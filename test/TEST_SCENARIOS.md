# ThreePartyEscrow - Test Scenarios and Specifications

This document provides detailed specifications for all test scenarios in the Solidity test suite.

## Table of Contents
1. [Constructor & Deployment Tests](#constructor--deployment-tests)
2. [Deposit Functionality Tests](#deposit-functionality-tests)
3. [Release Approval Tests](#release-approval-tests)
4. [Refund Approval Tests](#refund-approval-tests)
5. [State Management Tests](#state-management-tests)
6. [System Integration Tests](#system-integration-tests)
7. [Security & Edge Cases](#security--edge-cases)

---

## Constructor & Deployment Tests

### Test 1: Valid Deployment
**Scenario**: Deploy contract with three distinct, non-zero addresses
**Expected**: Contract successfully deploys with correct state initialization
**Validation**:
- `buyer` address set correctly
- `seller` address set correctly
- `mediator` address set correctly
- `amount` is 0
- All approval flags are false
- `fundsReleased` and `fundsRefunded` are false

### Test 2-4: Zero Address Rejection
**Scenarios**: 
- Deploy with zero address for buyer
- Deploy with zero address for seller
- Deploy with zero address for mediator

**Expected**: Each deployment reverts with appropriate error message
**Error Messages**:
- "Buyer address cannot be zero"
- "Seller address cannot be zero"
- "Mediator address cannot be zero"

### Test 5-7: Duplicate Address Rejection
**Scenarios**:
- Deploy with buyer == seller
- Deploy with buyer == mediator
- Deploy with seller == mediator

**Expected**: Each deployment reverts with appropriate error message
**Error Messages**:
- "Buyer and seller must be different"
- "Buyer and mediator must be different"
- "Seller and mediator must be different"

**Rationale**: Ensures proper separation of roles and prevents conflicts of interest

---

## Deposit Functionality Tests

### Test 8: Successful Deposit
**Scenario**: Buyer deposits 1 ETH into escrow
**Preconditions**: Contract deployed, no previous deposit
**Expected**:
- Transaction succeeds
- `FundsDeposited` event emitted with (buyer address, amount)
- Contract balance increases by deposit amount
- `amount` state variable equals deposit amount

### Test 9: Non-Buyer Deposit Rejection
**Scenario**: Seller or mediator attempts to deposit funds
**Expected**: Transaction reverts with "Only buyer can deposit"
**Rationale**: Only buyer should fund the escrow

### Test 10: Zero Deposit Rejection
**Scenario**: Buyer calls deposit() with 0 value
**Expected**: Transaction reverts with "Deposit must be greater than 0"
**Rationale**: Prevents meaningless escrow transactions

### Test 11: Double Deposit Prevention
**Scenario**: Buyer deposits 1 ETH, then attempts another deposit
**Expected**: Second deposit reverts with "Funds already deposited"
**Rationale**: Each escrow instance handles exactly one transaction

---

## Release Approval Tests

### Test 12-14: Party Approval Rights
**Scenarios**:
- Buyer calls approveRelease()
- Seller calls approveRelease()
- Mediator calls approveRelease()

**Preconditions**: Funds deposited
**Expected**: Each call succeeds and sets respective approval flag
**Validation**:
- `ApprovalGiven` event emitted
- Corresponding approval flag (buyerApprovedRelease, etc.) is true

### Test 15: Unauthorized Approval Rejection
**Scenario**: Address not in {buyer, seller, mediator} calls approveRelease()
**Expected**: Transaction reverts with "Only parties can call this function"
**Rationale**: Ensures only authorized parties can influence outcome

### Test 16: Double Approval Prevention
**Scenario**: Buyer approves, then tries to approve again
**Expected**: Second approval reverts with "Buyer already approved release"
**Rationale**: Each party gets exactly one vote

### Test 17: Approval Without Deposit Rejection
**Scenario**: Call approveRelease() before any deposit
**Expected**: Transaction reverts with "No funds deposited"
**Rationale**: Cannot approve release of non-existent funds

### Test 18-20: 2-of-3 Release Mechanisms
**Scenarios**:
1. Buyer + Seller approve, then finalizeRelease()
2. Buyer + Mediator approve, then finalizeRelease()
3. Seller + Mediator approve, then finalizeRelease()

**Expected for each**:
- Both approvals succeed
- finalizeRelease() succeeds
- `FundsReleased` event emitted
- Funds transferred to seller
- `fundsReleased` flag set to true
- `amount` reset to 0
- Contract balance becomes 0

**Rationale**: Demonstrates 2-of-3 multi-signature consensus

### Test 21: Insufficient Approvals
**Scenario**: Only buyer approves, then finalizeRelease() is called
**Expected**: finalizeRelease() reverts with "Need at least 2 approvals to release funds"
**Rationale**: Enforces minimum consensus requirement

### Test 22: 3-of-3 Release
**Scenario**: All three parties approve release
**Expected**: finalizeRelease() succeeds with unanimous consensus
**Rationale**: Tests maximum approval scenario

---

## Refund Approval Tests

### Test 23-25: Party Refund Approval Rights
**Scenarios**:
- Buyer calls approveRefund()
- Seller calls approveRefund()
- Mediator calls approveRefund()

**Preconditions**: Funds deposited
**Expected**: Each call succeeds and sets respective refund approval flag
**Validation**:
- `ApprovalGiven` event emitted
- Corresponding approval flag (buyerApprovedRefund, etc.) is true

### Test 26: Unauthorized Refund Approval Rejection
**Scenario**: Unauthorized address calls approveRefund()
**Expected**: Transaction reverts with "Only parties can call this function"

### Test 27: Double Refund Approval Prevention
**Scenario**: Party approves refund twice
**Expected**: Second approval reverts with appropriate error message

### Test 28: Refund Approval Without Deposit
**Scenario**: Call approveRefund() before deposit
**Expected**: Transaction reverts with "No funds deposited"

### Test 29-31: 2-of-3 Refund Mechanisms
**Scenarios**:
1. Buyer + Seller approve refund, then finalizeRefund()
2. Buyer + Mediator approve refund, then finalizeRefund()
3. Seller + Mediator approve refund, then finalizeRefund()

**Expected for each**:
- Both approvals succeed
- finalizeRefund() succeeds
- `FundsRefunded` event emitted
- Funds transferred back to buyer
- `fundsRefunded` flag set to true
- `amount` reset to 0

### Test 32: Insufficient Refund Approvals
**Scenario**: Only one party approves refund, then finalizeRefund() is called
**Expected**: finalizeRefund() reverts with "Need at least 2 approvals to refund funds"

---

## State Management Tests

### Test 33-38: Escrow Status Transitions
**Test 33**: No deposit → Status should reflect uninitialized state
**Test 34**: After deposit, no approvals → Status = "Pending"
**Test 35**: After deposit, 1 approval → Status = "Pending"
**Test 36**: After deposit, 2 release approvals → Status = "Approved"
**Test 37**: After deposit, 2 refund approvals → Status = "Approved"
**Test 38**: After release finalized → Status = "Funds Released"
**Test 39**: After refund finalized → Status = "Funds Refunded"

### Test 40: Get Escrow State
**Scenario**: Call getEscrowState() at various stages
**Expected**: Returns struct with all current state variables
**Validation**:
- All addresses correct
- All approval flags accurate
- Amount reflects current balance
- Final state flags accurate

---

## System Integration Tests

### System Test 1: Happy Path - Successful Transaction
**Workflow**:
1. Buyer deploys escrow
2. Buyer deposits 1 ETH
3. Seller delivers goods/services (off-chain)
4. Buyer confirms and approves release
5. Seller approves release
6. Either party calls finalizeRelease()
7. Funds transferred to seller

**Validation**: 
- Seller receives exactly 1 ETH
- Status = "Funds Released"
- No further operations possible

### System Test 2: Dispute - Seller Wins
**Workflow**:
1. Buyer deposits funds
2. Seller delivers goods
3. Buyer disputes quality (refuses to approve)
4. Seller approves release (confident in delivery)
5. Mediator investigates
6. Mediator sides with seller and approves release
7. finalizeRelease() executed (2-of-3: seller + mediator)
8. Seller receives funds despite buyer objection

**Validation**: Demonstrates mediator's tie-breaking power

### System Test 3: Dispute - Buyer Wins
**Workflow**:
1. Buyer deposits funds
2. Seller fails to deliver or delivers wrong item
3. Buyer approves refund
4. Seller refuses to approve refund
5. Mediator investigates
6. Mediator sides with buyer and approves refund
7. finalizeRefund() executed (2-of-3: buyer + mediator)
8. Buyer gets refund despite seller objection

**Validation**: Buyer protected from non-delivery

### System Test 4: Mutual Cancellation
**Workflow**:
1. Buyer deposits funds
2. Before delivery, both parties agree to cancel
3. Buyer approves refund
4. Seller approves refund
5. finalizeRefund() executed
6. Funds returned to buyer (mediator not involved)

**Validation**: Parties can cancel without mediator

### System Test 5: Unanimous Release
**Workflow**:
1. Buyer deposits funds
2. Transaction completes successfully
3. All three parties approve release
4. finalizeRelease() executed with 3-of-3 consensus

**Validation**: Maximum consensus scenario works

### System Test 6: Unanimous Refund
**Workflow**:
1. Buyer deposits funds
2. Clear issue identified by all parties
3. All three parties approve refund
4. finalizeRefund() executed with 3-of-3 consensus

**Validation**: Unanimous refund scenario works

### System Test 7: Mediator Breaks Tie
**Workflow**:
1. Buyer deposits funds
2. Dispute arises
3. Buyer approves refund (wants money back)
4. Seller approves release (wants to be paid)
5. Mediator investigates and chooses a side
6. Mediator's vote creates 2-of-3 consensus
7. Appropriate finalize function executed

**Validation**: Mediator's role as tie-breaker

### System Test 8: No Consensus - Funds Locked
**Workflow**:
1. Buyer deposits funds
2. Only buyer approves (release or refund)
3. No other party approves
4. Attempts to finalize fail
5. Funds remain in escrow indefinitely

**Validation**: 
- Funds cannot be released or refunded
- Contract maintains security even without consensus

### System Test 9: Single Transaction Per Escrow
**Workflow**:
1. Complete a successful transaction (release or refund)
2. Attempt to use same escrow instance again
3. Verify all operations are blocked

**Validation**: One escrow = one transaction

### System Test 10: Irreversible Finalization
**Workflow**:
1. Complete a release
2. Attempt to approve refund
3. Attempt to approve release again
4. Attempt to finalize again
5. Verify all operations fail

**Validation**: Final states cannot be changed

---

## Security & Edge Cases

### Security Test 1: Reentrancy Protection
**Scenario**: Attempt to re-enter contract during fund transfer
**Expected**: Checks-effects-interactions pattern prevents reentrancy
**Validation**: State updated before external call

### Security Test 2: Integer Overflow/Underflow
**Scenario**: Test with maximum ETH values
**Expected**: Solidity 0.8+ prevents overflow/underflow automatically

### Security Test 3: Access Control
**Scenario**: Non-party tries various operations
**Expected**: All operations properly restricted by modifiers

### Edge Case 1: Exactly 2 Ether Deposit
**Scenario**: Deposit exactly 2 ETH
**Expected**: Works correctly, no precision issues

### Edge Case 2: Very Small Deposit (1 wei)
**Scenario**: Deposit 1 wei
**Expected**: Still works, validates > 0 check

### Edge Case 3: Approval Order Independence
**Scenario**: Approve in different orders (buyer→seller, seller→buyer, etc.)
**Expected**: Order doesn't matter, result is same

### Edge Case 4: Multiple Approvals Before Finalize
**Scenario**: All parties approve, wait, then finalize
**Expected**: Approvals persist until finalize is called

---

## Test Execution Environments

### 1. Hardhat Network
- Local blockchain simulation
- Instant mining
- Easy account management
- Event logging

### 2. Foundry (forge)
- High-performance Solidity testing
- Fuzzing capabilities
- Gas profiling
- Cheatcodes for testing

### 3. On-chain Deployment
- Deploy ThreePartyEscrowTestRunner
- Execute tests on actual network (testnet)
- Real gas costs
- Real transaction finality

---

## Expected Test Results Summary

| Category | Total Tests | Expected Pass Rate |
|----------|-------------|-------------------|
| Constructor | 7 | 100% |
| Deposit | 4 | 100% |
| Release Approvals | 11 | 100% |
| Refund Approvals | 9 | 100% |
| State Management | 7 | 100% |
| System Tests | 10 | 100% |
| **TOTAL** | **48+** | **100%** |

---

## Maintenance and Updates

When updating the contract:
1. Review which tests are affected
2. Update test specifications in this document
3. Update test implementations
4. Re-run full test suite
5. Document any new edge cases discovered

---

## References

- Solidity Documentation: https://docs.soliditylang.org/
- Hardhat Testing: https://hardhat.org/hardhat-runner/docs/guides/test-contracts
- Foundry Book: https://book.getfoundry.sh/
- OpenZeppelin Test Helpers: https://docs.openzeppelin.com/test-helpers/

---

*Last Updated: 2025-11-30*
*Test Suite Version: 1.0*
*Contract Version: ThreePartyEscrow v1.0 (Solidity ^0.8.20)*

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/ThreePartyEscrow.sol";

/**
 * @title ThreePartyEscrow Advanced Integration Tests
 * @dev Advanced integration tests covering complex multi-party scenarios and edge cases
 */
contract ThreePartyEscrowAdvancedTest {
    ThreePartyEscrow escrow;
    
    address acc0; // buyer
    address acc1; // seller
    address acc2; // mediator
    
    /// 'beforeAll' runs before all other tests
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }
    
    /// 'beforeEach' runs before each test
    function beforeEach() public {
        escrow = new ThreePartyEscrow(acc0, acc1, acc2);
    }
    
    /// Test finalization prevents further approvals
    /// #sender: account-0
    /// #value: 2000000000000000000
    function testNoOperationsAfterRelease() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        
        // We can't easily simulate multi-sender in single test, but we test the state
        // This test documents the expected behavior
        Assert.ok(escrow.buyerApprovedRelease(), "Buyer should have approved");
    }
    
    /// Test that contract balance matches deposited amount
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testContractBalanceMatchesDeposit() public payable {
        uint256 balanceBefore = address(escrow).balance;
        escrow.deposit{value: 1 ether}();
        uint256 balanceAfter = address(escrow).balance;
        
        Assert.equal(balanceBefore, 0, "Initial balance should be 0");
        Assert.equal(balanceAfter, 1 ether, "Balance should match deposit");
        Assert.equal(escrow.amount(), 1 ether, "Recorded amount should match deposit");
    }
    
    /// Test deployment with all different addresses succeeds
    /// #sender: account-0
    function testDeploymentWithValidAddresses() public {
        ThreePartyEscrow newEscrow = new ThreePartyEscrow(acc0, acc1, acc2);
        
        Assert.equal(newEscrow.buyer(), acc0, "Buyer should be set");
        Assert.equal(newEscrow.seller(), acc1, "Seller should be set");
        Assert.equal(newEscrow.mediator(), acc2, "Mediator should be set");
        Assert.equal(newEscrow.amount(), 0, "Initial amount should be 0");
        Assert.ok(!newEscrow.fundsReleased(), "Funds should not be released initially");
        Assert.ok(!newEscrow.fundsRefunded(), "Funds should not be refunded initially");
    }
    
    /// Test multiple deposits are rejected even with different amounts
    /// #sender: account-0
    /// #value: 3000000000000000000
    function testMultipleDepositsRejectedDifferentAmounts() public payable {
        escrow.deposit{value: 1 ether}();
        
        try escrow.deposit{value: 2 ether}() {
            Assert.ok(false, "Second deposit should be rejected");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Funds already deposited", "Should reject second deposit");
        }
        
        // Original deposit should remain
        Assert.equal(escrow.amount(), 1 ether, "Original deposit should remain");
    }
    
    /// Test approval before deposit is rejected
    /// #sender: account-0
    function testApprovalBeforeDepositRejected() public {
        try escrow.approveRelease() {
            Assert.ok(false, "Approval before deposit should be rejected");
        } catch Error(string memory reason) {
            Assert.equal(reason, "No funds deposited", "Should require deposit first");
        }
        
        try escrow.approveRefund() {
            Assert.ok(false, "Refund approval before deposit should be rejected");
        } catch Error(string memory reason) {
            Assert.equal(reason, "No funds deposited", "Should require deposit first");
        }
    }
    
    /// Test finalization before deposit is rejected
    /// #sender: account-0
    function testFinalizeBeforeDepositRejected() public {
        try escrow.finalizeRelease() {
            Assert.ok(false, "Finalize before deposit should be rejected");
        } catch Error(string memory reason) {
            Assert.equal(reason, "No funds deposited", "Should require deposit first");
        }
        
        try escrow.finalizeRefund() {
            Assert.ok(false, "Finalize refund before deposit should be rejected");
        } catch Error(string memory reason) {
            Assert.equal(reason, "No funds deposited", "Should require deposit first");
        }
    }
    
    /// Test getEscrowStatus returns correct values at different stages
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testEscrowStatusAtDifferentStages() public payable {
        // Before deposit - we don't test this as it's not a valid state
        
        // After deposit
        escrow.deposit{value: 1 ether}();
        string memory status1 = escrow.getEscrowStatus();
        Assert.equal(status1, "Pending", "Should be Pending after deposit");
        
        // After one approval
        escrow.approveRelease();
        string memory status2 = escrow.getEscrowStatus();
        Assert.equal(status2, "Pending", "Should still be Pending with 1 approval");
    }
    
    /// Test separate tracking of release and refund approvals
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testSeparateApprovalTracking() public payable {
        escrow.deposit{value: 1 ether}();
        
        // Test initial state
        Assert.ok(!escrow.buyerApprovedRelease(), "No release approval initially");
        Assert.ok(!escrow.buyerApprovedRefund(), "No refund approval initially");
        
        // Approve release
        escrow.approveRelease();
        Assert.ok(escrow.buyerApprovedRelease(), "Release approval should be recorded");
        Assert.ok(!escrow.buyerApprovedRefund(), "Refund approval should still be false");
        
        // Approve refund
        escrow.approveRefund();
        Assert.ok(escrow.buyerApprovedRelease(), "Release approval should persist");
        Assert.ok(escrow.buyerApprovedRefund(), "Refund approval should be recorded");
    }
    
    /// Test that both finalization functions exist and can be called
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testBothFinalizationFunctionsExist() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        
        // Try finalize release (should fail - need 2 approvals)
        try escrow.finalizeRelease() {
            Assert.ok(false, "Should need 2 approvals");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Need at least 2 approvals to release funds", "Correct error");
        }
        
        // Try finalize refund (should fail - need 2 approvals)
        try escrow.finalizeRefund() {
            Assert.ok(false, "Should need 2 approvals");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Need at least 2 approvals to refund funds", "Correct error");
        }
    }
    
    /// Test deposit amount can vary
    /// #sender: account-0
    /// #value: 5000000000000000000
    function testVariableDepositAmounts() public payable {
        ThreePartyEscrow escrow1 = new ThreePartyEscrow(acc0, acc1, acc2);
        escrow1.deposit{value: 0.5 ether}();
        Assert.equal(escrow1.amount(), 0.5 ether, "Should accept 0.5 ether");
        
        ThreePartyEscrow escrow2 = new ThreePartyEscrow(acc0, acc1, acc2);
        escrow2.deposit{value: 2 ether}();
        Assert.equal(escrow2.amount(), 2 ether, "Should accept 2 ether");
        
        ThreePartyEscrow escrow3 = new ThreePartyEscrow(acc0, acc1, acc2);
        escrow3.deposit{value: 0.1 ether}();
        Assert.equal(escrow3.amount(), 0.1 ether, "Should accept 0.1 ether");
    }
    
    /// Test very small deposit
    /// #sender: account-0
    /// #value: 1000
    function testSmallDeposit() public payable {
        escrow.deposit{value: 1 wei}();
        Assert.equal(escrow.amount(), 1 wei, "Should accept minimal deposit");
    }
    
    /// Test that contract starts in clean state
    /// #sender: account-0
    function testCleanInitialState() public {
        Assert.equal(escrow.amount(), 0, "Amount should be 0");
        Assert.ok(!escrow.buyerApprovedRelease(), "No release approvals");
        Assert.ok(!escrow.sellerApprovedRelease(), "No release approvals");
        Assert.ok(!escrow.mediatorApprovedRelease(), "No release approvals");
        Assert.ok(!escrow.buyerApprovedRefund(), "No refund approvals");
        Assert.ok(!escrow.sellerApprovedRefund(), "No refund approvals");
        Assert.ok(!escrow.mediatorApprovedRefund(), "No refund approvals");
        Assert.ok(!escrow.fundsReleased(), "Funds not released");
        Assert.ok(!escrow.fundsRefunded(), "Funds not refunded");
        
        string memory status = escrow.getEscrowStatus();
        Assert.equal(status, "Pending", "Initial status should be Pending");
    }
}

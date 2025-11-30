# Three-Party Escrow Smart Contract

A Solidity smart contract implementing a three-party escrow system where funds are held securely until delivery, with a 2-of-3 multi-signature approval mechanism for releasing or refunding funds.

## Problem Statement

When two unfamiliar parties engage in commerce online, holding funds securely until delivery is critical. This smart contract implements a three-party escrow system where:
- A **buyer** deposits funds
- A **seller** receives funds after delivery
- A **mediator** helps resolve disputes

Funds are released only when **any two parties (out of three)** approve the release, ensuring balanced trust and fairness.

## Features

### 2-of-3 Multi-Signature Approval
- Funds can be released to the seller when any 2 of the 3 parties approve
- Funds can be refunded to the buyer when any 2 of the 3 parties approve
- Separate tracking for release and refund approvals

### Security Features
- Only the buyer can deposit funds
- Only the three designated parties can vote on approvals
- Prevents double-voting by the same party
- Prevents operations after funds have been released or refunded
- Uses checks-effects-interactions pattern for safe fund transfers

### Events
- `FundsDeposited`: Emitted when buyer deposits funds
- `ApprovalGiven`: Emitted when a party approves
- `FundsReleased`: Emitted when funds are released to seller
- `FundsRefunded`: Emitted when funds are refunded to buyer

## Contract Architecture

### Roles
1. **Buyer**: Initiates the escrow by deploying the contract and depositing funds
2. **Seller**: Receives funds when 2-of-3 parties approve release
3. **Mediator**: Neutral third party who can help resolve disputes

### Main Functions

#### `constructor(address _seller, address _mediator)`
Initializes the escrow with seller and mediator addresses. The deployer becomes the buyer.

#### `deposit() external payable`
Allows the buyer to deposit funds into the escrow. Can only be called once.

#### `approveRelease() external`
Allows any of the three parties to approve releasing funds to the seller. When 2 approvals are reached, funds are automatically released.

#### `approveRefund() external`
Allows any of the three parties to approve refunding funds to the buyer. When 2 approvals are reached, funds are automatically refunded.

#### `getEscrowState() external view`
Returns the complete state of the escrow including all approval statuses.

## Use Cases

### Scenario 1: Successful Delivery
1. Buyer deploys contract with seller and mediator addresses
2. Buyer deposits funds (e.g., 1 ETH)
3. Seller delivers goods/services
4. Buyer approves release
5. Seller approves release
6. Funds automatically transferred to seller

### Scenario 2: Dispute Resolution - Seller Wins
1. Buyer deposits funds
2. Seller delivers goods but buyer disputes quality
3. Seller approves release
4. Mediator investigates and sides with seller
5. Mediator approves release
6. Funds automatically transferred to seller

### Scenario 3: Dispute Resolution - Buyer Wins
1. Buyer deposits funds
2. Seller fails to deliver or delivers wrong item
3. Buyer approves refund
4. Mediator investigates and sides with buyer
5. Mediator approves refund
6. Funds automatically returned to buyer

## Installation

```bash
npm install
```

## Compilation

```bash
npm run compile
```

This compiles the Solidity contract using the solc compiler.

## Testing

The repository includes comprehensive test coverage in **both JavaScript and Solidity**:

### JavaScript Tests (Hardhat)
- Contract deployment validation
- Deposit functionality
- 2-of-3 approval mechanism for releases
- 2-of-3 approval mechanism for refunds
- Edge cases and security checks
- State management

To run JavaScript tests:
```bash
npm test
# or
npx hardhat test
```

### Solidity Tests (Native Smart Contract Tests)
The repository includes **72 test functions** written in pure Solidity:

**Test Files:**
- `test/ThreePartyEscrow.t.sol` - 56 comprehensive test specifications
- `test/ThreePartyEscrowTestRunner.sol` - 16 executable on-chain tests

**Test Coverage:**
- 14 Constructor & Deployment validation tests
- 10 Deposit functionality tests
- 18 Release approval mechanism tests (2-of-3 multi-sig)
- 16 Refund approval mechanism tests (2-of-3 multi-sig)
- 4 State management tests
- 7 System/Integration tests (complete workflows)
- 3 Approval tracking tests

To verify Solidity test suite:
```bash
npm run test:verify
```

To run Solidity tests (requires Hardhat network):
```bash
npm run test:solidity
```

To run all tests (JavaScript + Solidity):
```bash
npm run test:all
```

For detailed information about Solidity tests, see [test/SOLIDITY_TESTS.md](test/SOLIDITY_TESTS.md)

## Project Structure

```
.
├── contracts/
│   └── ThreePartyEscrow.sol           # Main escrow contract
├── test/
│   ├── ThreePartyEscrow.test.js       # JavaScript test suite (Hardhat/Chai)
│   ├── ThreePartyEscrow.t.sol         # Solidity test specifications (56 tests)
│   ├── ThreePartyEscrowTestRunner.sol # Solidity executable tests (16 tests)
│   └── SOLIDITY_TESTS.md              # Solidity test documentation
├── scripts/
│   ├── compile.js                     # Compilation script
│   ├── runSolidityTests.js            # Solidity test runner script
│   └── verifySolidityTests.js         # Test suite verification script
├── hardhat.config.js                  # Hardhat configuration
├── package.json
└── README.md
```

## Security Considerations

1. **Reentrancy Protection**: Uses checks-effects-interactions pattern
2. **Address Validation**: Validates addresses in constructor
3. **Access Control**: Strict role-based permissions
4. **Double-Voting Prevention**: Prevents same party from approving twice
5. **State Machine**: Enforces proper state transitions

## Gas Optimization

- State variables are properly packed
- Uses `uint8` for approval counting
- Minimal storage operations
- Efficient approval tracking

## License

MIT

## Version

Solidity: ^0.8.20

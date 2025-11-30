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

The repository includes comprehensive test coverage in two formats:

### 1. JavaScript Tests (Hardhat)
To run JavaScript tests with Hardhat:
```bash
npx hardhat test
```

### 2. Solidity Tests (Remix Framework)
The repository includes Solidity-based tests using the Remix testing framework:
- `test/ThreePartyEscrow_test.sol` - Unit tests
- `test/ThreePartyEscrow_system_test.sol` - System/integration tests
- `test/ThreePartyEscrow_advanced_test.sol` - Advanced edge case tests

To run Remix tests, see [REMIX_TESTING.md](REMIX_TESTING.md) for detailed instructions.

**Test Coverage:**
- Contract deployment validation
- Deposit functionality
- 2-of-3 approval mechanism for releases
- 2-of-3 approval mechanism for refunds
- Edge cases and security checks
- State management
- Complete workflow scenarios
- Multi-party interactions

## Project Structure

```
.
├── contracts/
│   └── ThreePartyEscrow.sol              # Main escrow contract
├── test/
│   ├── ThreePartyEscrow.test.js          # Hardhat/JavaScript tests
│   ├── ThreePartyEscrow.standalone.test.js
│   ├── ThreePartyEscrow_test.sol         # Remix unit tests
│   ├── ThreePartyEscrow_system_test.sol  # Remix system tests
│   └── ThreePartyEscrow_advanced_test.sol # Remix advanced tests
├── scripts/
│   ├── compile.js                        # Compilation script
│   └── verify.js                         # Verification script
├── hardhat.config.js                     # Hardhat configuration
├── package.json
├── README.md
└── REMIX_TESTING.md                      # Remix testing guide
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

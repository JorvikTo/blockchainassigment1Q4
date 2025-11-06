# Three-Party Escrow - Usage Guide

This guide explains how to use the ThreePartyEscrow smart contract.

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Compile the Contract

```bash
npm run compile
```

### 3. Verify Contract Features

```bash
npm run verify
```

## Detailed Usage

### Deploying the Contract

The buyer deploys the contract and specifies the seller and mediator addresses:

```javascript
import { ethers } from "hardhat";

// Get signers
const [buyer, seller, mediator] = await ethers.getSigners();

// Deploy contract
const ThreePartyEscrow = await ethers.getContractFactory("ThreePartyEscrow");
const escrow = await ThreePartyEscrow.connect(buyer).deploy(
  seller.address,
  mediator.address
);
await escrow.waitForDeployment();

console.log("Escrow deployed at:", await escrow.getAddress());
```

### Making a Deposit

Only the buyer can deposit funds:

```javascript
// Deposit 1 ETH
const depositAmount = ethers.parseEther("1.0");
await escrow.connect(buyer).deposit({ value: depositAmount });
```

### Approving Release (Happy Path)

When delivery is successful, 2 of 3 parties approve to release funds to the seller:

```javascript
// Option 1: Buyer and Seller approve
await escrow.connect(buyer).approveRelease();
await escrow.connect(seller).approveRelease(); // Funds released after 2nd approval

// Option 2: Buyer and Mediator approve
await escrow.connect(buyer).approveRelease();
await escrow.connect(mediator).approveRelease(); // Funds released

// Option 3: Seller and Mediator approve
await escrow.connect(seller).approveRelease();
await escrow.connect(mediator).approveRelease(); // Funds released
```

### Approving Refund (Dispute Resolution)

When there's a problem, 2 of 3 parties can approve a refund:

```javascript
// Option 1: Buyer and Seller agree on refund
await escrow.connect(buyer).approveRefund();
await escrow.connect(seller).approveRefund(); // Funds refunded after 2nd approval

// Option 2: Buyer and Mediator approve refund
await escrow.connect(buyer).approveRefund();
await escrow.connect(mediator).approveRefund(); // Funds refunded

// Option 3: Seller and Mediator approve refund
await escrow.connect(seller).approveRefund();
await escrow.connect(mediator).approveRefund(); // Funds refunded
```

### Checking Contract State

You can query the current state at any time:

```javascript
const state = await escrow.getEscrowState();

console.log("Buyer:", state._buyer);
console.log("Seller:", state._seller);
console.log("Mediator:", state._mediator);
console.log("Amount:", ethers.formatEther(state._amount), "ETH");
console.log("Buyer approved release:", state._buyerApprovedRelease);
console.log("Seller approved release:", state._sellerApprovedRelease);
console.log("Mediator approved release:", state._mediatorApprovedRelease);
console.log("Buyer approved refund:", state._buyerApprovedRefund);
console.log("Seller approved refund:", state._sellerApprovedRefund);
console.log("Mediator approved refund:", state._mediatorApprovedRefund);
console.log("Funds released:", state._fundsReleased);
console.log("Funds refunded:", state._fundsRefunded);
```

## Real-World Example: E-commerce Purchase

### Scenario

Alice wants to buy a laptop from Bob for 1 ETH. Carol is a trusted mediator.

### Steps

1. **Setup**: Alice deploys the contract with Bob as seller and Carol as mediator
   ```javascript
   const escrow = await ThreePartyEscrow.deploy(bob.address, carol.address);
   ```

2. **Payment**: Alice deposits 1 ETH
   ```javascript
   await escrow.connect(alice).deposit({ value: ethers.parseEther("1.0") });
   ```

3. **Delivery**: Bob ships the laptop

4. **Successful Delivery**:
   - Alice receives laptop and approves
   - Bob confirms delivery and approves
   ```javascript
   await escrow.connect(alice).approveRelease();
   await escrow.connect(bob).approveRelease();
   // Bob receives 1 ETH automatically
   ```

### Alternative: Dispute Scenario

If Alice receives a damaged laptop:

1. Alice disputes and approves refund
2. Carol investigates the case
3. Carol sides with Alice and approves refund
   ```javascript
   await escrow.connect(alice).approveRefund();
   await escrow.connect(carol).approveRefund();
   // Alice gets 1 ETH back automatically
   ```

## Security Features

### Access Control
- Only the buyer can deposit
- Only the three designated parties can approve
- Each party can only vote once per approval type

### State Management
- Once funds are released, no further actions possible
- Once funds are refunded, no further actions possible
- Prevents reentrancy attacks using checks-effects-interactions pattern

### Validation
- Prevents zero addresses for seller and mediator
- Prevents same address for seller and mediator
- Requires positive deposit amount
- Prevents multiple deposits

## Events

Monitor these events to track contract activity:

- `FundsDeposited(address indexed buyer, uint256 amount)` - When buyer deposits
- `ApprovalGiven(address indexed approver)` - When any party approves
- `FundsReleased(address indexed seller, uint256 amount)` - When funds go to seller
- `FundsRefunded(address indexed buyer, uint256 amount)` - When funds go back to buyer

Example event listener:

```javascript
escrow.on("FundsDeposited", (buyer, amount) => {
  console.log(`${buyer} deposited ${ethers.formatEther(amount)} ETH`);
});

escrow.on("ApprovalGiven", (approver) => {
  console.log(`${approver} gave approval`);
});

escrow.on("FundsReleased", (seller, amount) => {
  console.log(`${seller} received ${ethers.formatEther(amount)} ETH`);
});
```

## Gas Considerations

Approximate gas costs (may vary):
- Deploy contract: ~700,000 gas
- Deposit: ~50,000 gas
- First approval: ~50,000 gas
- Second approval (triggers release): ~80,000 gas

## Best Practices

1. **Choose a Trusted Mediator**: The mediator has significant power in disputes
2. **Document Terms**: Keep off-chain records of the transaction terms
3. **Communicate**: All parties should communicate about delivery and quality
4. **Act Promptly**: Don't leave funds in escrow indefinitely
5. **Test First**: Use testnets before deploying to mainnet

## Troubleshooting

**Error: "Only buyer can deposit"**
- Solution: Make sure you're calling deposit from the buyer's account

**Error: "Funds already deposited"**
- Solution: You can only deposit once per contract. Create a new contract for a new transaction.

**Error: "No funds deposited"**
- Solution: Buyer must deposit before any approvals can be made

**Error: "Already approved"**
- Solution: Each party can only approve once. You cannot change your vote.

**Error: "Funds already released or refunded"**
- Solution: The transaction is complete. No further actions possible.

## Support

For issues or questions:
1. Check the contract code in `contracts/ThreePartyEscrow.sol`
2. Review the test cases in `test/ThreePartyEscrow.test.js`
3. Run the verification script: `npm run verify`

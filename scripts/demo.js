import { ethers } from "hardhat";

/**
 * Example script demonstrating how to interact with the ThreePartyEscrow contract
 * 
 * This script shows a complete escrow flow:
 * 1. Deploy contract
 * 2. Buyer deposits funds
 * 3. Buyer and seller approve release
 * 4. Funds are released to seller
 */
async function main() {
  const [buyer, seller, mediator] = await ethers.getSigners();
  
  console.log("=== Three-Party Escrow Demo ===\n");
  console.log("Participants:");
  console.log("  Buyer:", buyer.address);
  console.log("  Seller:", seller.address);
  console.log("  Mediator:", mediator.address);
  console.log();
  
  // Step 1: Deploy the contract
  console.log("Step 1: Deploying escrow contract...");
  const ThreePartyEscrow = await ethers.getContractFactory("ThreePartyEscrow");
  const escrow = await ThreePartyEscrow.deploy(buyer.address, seller.address, mediator.address);
  await escrow.waitForDeployment();
  console.log("  Contract deployed at:", await escrow.getAddress());
  console.log();
  
  // Step 2: Buyer deposits funds
  console.log("Step 2: Buyer deposits 1 ETH...");
  const depositAmount = ethers.parseEther("1.0");
  const depositTx = await escrow.connect(buyer).deposit({ value: depositAmount });
  await depositTx.wait();
  console.log("  Deposited:", ethers.formatEther(depositAmount), "ETH");
  console.log("  Escrow balance:", ethers.formatEther(await ethers.provider.getBalance(await escrow.getAddress())), "ETH");
  console.log("  Status:", await escrow.getEscrowStatus());
  console.log();
  
  // Check state
  let state = await escrow.getEscrowState();
  console.log("Current State:");
  console.log("  Amount in escrow:", ethers.formatEther(state._amount), "ETH");
  console.log("  Buyer approved release:", state._buyerApprovedRelease);
  console.log("  Seller approved release:", state._sellerApprovedRelease);
  console.log("  Mediator approved release:", state._mediatorApprovedRelease);
  console.log();
  
  // Step 3: Buyer approves release
  console.log("Step 3: Buyer approves release...");
  const buyerApproveTx = await escrow.connect(buyer).approveRelease();
  await buyerApproveTx.wait();
  console.log("  Buyer approval recorded");
  console.log("  Status:", await escrow.getEscrowStatus());
  
  state = await escrow.getEscrowState();
  console.log("  Buyer approved release:", state._buyerApprovedRelease);
  console.log("  Funds released:", state._fundsReleased);
  console.log();
  
  // Step 4: Seller approves release (2nd approval)
  console.log("Step 4: Seller approves release (2nd approval)...");
  const sellerApproveTx = await escrow.connect(seller).approveRelease();
  await sellerApproveTx.wait();
  console.log("  Seller approval recorded");
  console.log("  Status:", await escrow.getEscrowStatus());
  console.log();
  
  // Step 5: Finalize release
  console.log("Step 5: Finalizing release to seller...");
  const sellerBalanceBefore = await ethers.provider.getBalance(seller.address);
  console.log("  Seller balance before:", ethers.formatEther(sellerBalanceBefore), "ETH");
  
  const finalizeTx = await escrow.connect(buyer).finalizeRelease();
  await finalizeTx.wait();
  
  const sellerBalanceAfter = await ethers.provider.getBalance(seller.address);
  
  console.log("  Seller balance after:", ethers.formatEther(sellerBalanceAfter), "ETH");
  console.log("  Net gain:", ethers.formatEther(sellerBalanceAfter - sellerBalanceBefore), "ETH");
  console.log("  Status:", await escrow.getEscrowStatus());
  console.log();
  
  // Final state
  state = await escrow.getEscrowState();
  console.log("Final State:");
  console.log("  Buyer approved release:", state._buyerApprovedRelease);
  console.log("  Seller approved release:", state._sellerApprovedRelease);
  console.log("  Funds released:", state._fundsReleased);
  console.log("  Amount in escrow:", ethers.formatEther(state._amount), "ETH");
  console.log("  Escrow balance:", ethers.formatEther(await ethers.provider.getBalance(await escrow.getAddress())), "ETH");
  console.log();
  console.log("=== Demo Complete ===");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

import { ethers } from "hardhat";

/**
 * Deploy script for ThreePartyEscrow contract
 * 
 * Usage:
 * npx hardhat run scripts/deploy.js --network <network-name>
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying ThreePartyEscrow contract...");
  console.log("Deployer (Buyer):", deployer.address);
  console.log("Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
  
  // You need to provide seller and mediator addresses
  // These are example addresses - replace with actual addresses
  const sellerAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"; // Example
  const mediatorAddress = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"; // Example
  
  console.log("Seller address:", sellerAddress);
  console.log("Mediator address:", mediatorAddress);
  
  // Deploy the contract
  const ThreePartyEscrow = await ethers.getContractFactory("ThreePartyEscrow");
  const escrow = await ThreePartyEscrow.deploy(sellerAddress, mediatorAddress);
  
  await escrow.waitForDeployment();
  
  const escrowAddress = await escrow.getAddress();
  console.log("ThreePartyEscrow deployed to:", escrowAddress);
  
  // Verify deployment
  const buyer = await escrow.buyer();
  const seller = await escrow.seller();
  const mediator = await escrow.mediator();
  
  console.log("\nContract Details:");
  console.log("  Buyer:", buyer);
  console.log("  Seller:", seller);
  console.log("  Mediator:", mediator);
  console.log("\nDeployment successful!");
  
  return escrowAddress;
}

main()
  .then((address) => {
    console.log("\nContract deployed at:", address);
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

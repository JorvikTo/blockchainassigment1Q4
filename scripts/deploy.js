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
  console.log("Deployer:", deployer.address);
  console.log("Deployer balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");
  
  // You need to provide buyer, seller and mediator addresses
  // These are example addresses - replace with actual addresses
  const buyerAddress = deployer.address; // Or specify different address
  const sellerAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"; // Example
  const mediatorAddress = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"; // Example
  
  console.log("\nParticipants:");
  console.log("  Buyer:", buyerAddress);
  console.log("  Seller:", sellerAddress);
  console.log("  Mediator:", mediatorAddress);
  
  // Deploy the contract
  const ThreePartyEscrow = await ethers.getContractFactory("ThreePartyEscrow");
  const escrow = await ThreePartyEscrow.deploy(buyerAddress, sellerAddress, mediatorAddress);
  
  await escrow.waitForDeployment();
  
  const escrowAddress = await escrow.getAddress();
  console.log("\nThreePartyEscrow deployed to:", escrowAddress);
  
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

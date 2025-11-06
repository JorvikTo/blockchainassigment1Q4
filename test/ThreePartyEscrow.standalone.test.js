import { expect } from "chai";
import { ethers } from "ethers";
import fs from "fs";
import path from "path";

describe("ThreePartyEscrow", function () {
  let provider;
  let escrow;
  let buyer, seller, mediator, other;
  let escrowFactory;

  before(async function () {
    // Setup provider (using Hardhat's in-memory network)
    provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
    
    // Get accounts
    const accounts = await provider.listAccounts();
    buyer = await provider.getSigner(accounts[0].address);
    seller = await provider.getSigner(accounts[1].address);
    mediator = await provider.getSigner(accounts[2].address);
    other = await provider.getSigner(accounts[3].address);

    // Load compiled contract
    const artifactPath = path.join(process.cwd(), 'artifacts', 'contracts', 'ThreePartyEscrow.json');
    const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
    
    // Create contract factory
    escrowFactory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, buyer);
  });

  beforeEach(async function () {
    escrow = await escrowFactory.deploy(buyer.address, seller.address, mediator.address);
    await escrow.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct buyer", async function () {
      expect(await escrow.buyer()).to.equal(buyer.address);
    });

    it("Should set the correct seller", async function () {
      expect(await escrow.seller()).to.equal(seller.address);
    });

    it("Should set the correct mediator", async function () {
      expect(await escrow.mediator()).to.equal(mediator.address);
    });

    it("Should reject zero address for seller", async function () {
      await expect(
        escrowFactory.deploy(ethers.ZeroAddress, mediator.address)
      ).to.be.revertedWith("Seller address cannot be zero");
    });

    it("Should reject zero address for mediator", async function () {
      await expect(
        escrowFactory.deploy(seller.address, ethers.ZeroAddress)
      ).to.be.revertedWith("Mediator address cannot be zero");
    });

    it("Should reject same address for seller and mediator", async function () {
      await expect(
        escrowFactory.deploy(seller.address, seller.address)
      ).to.be.revertedWith("Seller and mediator must be different");
    });

    it("Should reject buyer being same as seller", async function () {
      await expect(
        escrowFactory.deploy(buyer.address, mediator.address)
      ).to.be.revertedWith("Buyer and seller must be different");
    });

    it("Should reject buyer being same as mediator", async function () {
      await expect(
        escrowFactory.deploy(seller.address, buyer.address)
      ).to.be.revertedWith("Buyer and mediator must be different");
    });
  });

  describe("Deposit", function () {
    it("Should allow buyer to deposit funds", async function () {
      const depositAmount = ethers.parseEther("1.0");
      await expect(escrow.connect(buyer).deposit({ value: depositAmount }))
        .to.emit(escrow, "FundsDeposited")
        .withArgs(buyer.address, depositAmount);
      
      expect(await escrow.amount()).to.equal(depositAmount);
    });

    it("Should reject deposit from non-buyer", async function () {
      await expect(
        escrow.connect(seller).deposit({ value: ethers.parseEther("1.0") })
      ).to.be.revertedWith("Only buyer can deposit");
    });

    it("Should reject deposit of zero amount", async function () {
      await expect(
        escrow.connect(buyer).deposit({ value: 0 })
      ).to.be.revertedWith("Deposit must be greater than 0");
    });

    it("Should reject multiple deposits", async function () {
      await escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") });
      await expect(
        escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") })
      ).to.be.revertedWith("Funds already deposited");
    });
  });

  describe("Release Approval - 2 of 3 mechanism", function () {
    beforeEach(async function () {
      await escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") });
    });

    it("Should allow buyer to approve release", async function () {
      await expect(escrow.connect(buyer).approveRelease())
        .to.emit(escrow, "ApprovalGiven")
        .withArgs(buyer.address);
      
      expect(await escrow.buyerApprovedRelease()).to.be.true;
    });

    it("Should allow seller to approve release", async function () {
      await expect(escrow.connect(seller).approveRelease())
        .to.emit(escrow, "ApprovalGiven")
        .withArgs(seller.address);
      
      expect(await escrow.sellerApprovedRelease()).to.be.true;
    });

    it("Should allow mediator to approve release", async function () {
      await expect(escrow.connect(mediator).approveRelease())
        .to.emit(escrow, "ApprovalGiven")
        .withArgs(mediator.address);
      
      expect(await escrow.mediatorApprovedRelease()).to.be.true;
    });

    it("Should reject approval from non-party", async function () {
      await expect(
        escrow.connect(other).approveRelease()
      ).to.be.revertedWith("Only parties can call this function");
    });

    it("Should reject double approval from same party", async function () {
      await escrow.connect(buyer).approveRelease();
      await expect(
        escrow.connect(buyer).approveRelease()
      ).to.be.revertedWith("Buyer already approved release");
    });

    it("Should release funds when buyer and seller approve", async function () {
      const depositAmount = ethers.parseEther("1.0");
      const sellerBalanceBefore = await provider.getBalance(seller.address);
      
      await escrow.connect(buyer).approveRelease();
      
      await expect(escrow.connect(seller).approveRelease())
        .to.emit(escrow, "FundsReleased")
        .withArgs(seller.address, depositAmount);
      
      expect(await escrow.fundsReleased()).to.be.true;
      expect(await escrow.amount()).to.equal(0);
      
      const sellerBalanceAfter = await provider.getBalance(seller.address);
      // Seller balance should increase (minus gas costs for transaction)
      expect(sellerBalanceAfter).to.be.greaterThan(sellerBalanceBefore);
    });

    it("Should release funds when buyer and mediator approve", async function () {
      const depositAmount = ethers.parseEther("1.0");
      const sellerBalanceBefore = await provider.getBalance(seller.address);
      
      await escrow.connect(buyer).approveRelease();
      await escrow.connect(mediator).approveRelease();
      
      expect(await escrow.fundsReleased()).to.be.true;
      expect(await escrow.amount()).to.equal(0);
      
      const sellerBalanceAfter = await provider.getBalance(seller.address);
      expect(sellerBalanceAfter).to.equal(sellerBalanceBefore + depositAmount);
    });

    it("Should release funds when seller and mediator approve", async function () {
      const depositAmount = ethers.parseEther("1.0");
      const sellerBalanceBefore = await provider.getBalance(seller.address);
      
      await escrow.connect(seller).approveRelease();
      await escrow.connect(mediator).approveRelease();
      
      expect(await escrow.fundsReleased()).to.be.true;
      expect(await escrow.amount()).to.equal(0);
      
      const sellerBalanceAfter = await provider.getBalance(seller.address);
      expect(sellerBalanceAfter).to.equal(sellerBalanceBefore + depositAmount);
    });

    it("Should not release funds with only one approval", async function () {
      await escrow.connect(buyer).approveRelease();
      
      expect(await escrow.fundsReleased()).to.be.false;
      expect(await escrow.amount()).to.equal(ethers.parseEther("1.0"));
    });
  });

  describe("Refund Approval - 2 of 3 mechanism", function () {
    beforeEach(async function () {
      await escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") });
    });

    it("Should allow buyer to approve refund", async function () {
      await expect(escrow.connect(buyer).approveRefund())
        .to.emit(escrow, "ApprovalGiven")
        .withArgs(buyer.address);
      
      expect(await escrow.buyerApprovedRefund()).to.be.true;
    });

    it("Should allow seller to approve refund", async function () {
      await expect(escrow.connect(seller).approveRefund())
        .to.emit(escrow, "ApprovalGiven")
        .withArgs(seller.address);
      
      expect(await escrow.sellerApprovedRefund()).to.be.true;
    });

    it("Should allow mediator to approve refund", async function () {
      await expect(escrow.connect(mediator).approveRefund())
        .to.emit(escrow, "ApprovalGiven")
        .withArgs(mediator.address);
      
      expect(await escrow.mediatorApprovedRefund()).to.be.true;
    });

    it("Should refund when buyer and seller approve", async function () {
      const depositAmount = ethers.parseEther("1.0");
      const buyerBalanceBefore = await provider.getBalance(buyer.address);
      
      await escrow.connect(seller).approveRefund();
      
      const tx = await escrow.connect(buyer).approveRefund();
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * (receipt.effectiveGasPrice || receipt.gasPrice);
      
      expect(await escrow.fundsRefunded()).to.be.true;
      expect(await escrow.amount()).to.equal(0);
      
      const buyerBalanceAfter = await provider.getBalance(buyer.address);
      expect(buyerBalanceAfter).to.equal(buyerBalanceBefore + depositAmount - gasUsed);
    });

    it("Should refund when buyer and mediator approve", async function () {
      const depositAmount = ethers.parseEther("1.0");
      const buyerBalanceBefore = await provider.getBalance(buyer.address);
      
      await escrow.connect(mediator).approveRefund();
      
      const tx = await escrow.connect(buyer).approveRefund();
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * (receipt.effectiveGasPrice || receipt.gasPrice);
      
      expect(await escrow.fundsRefunded()).to.be.true;
      expect(await escrow.amount()).to.equal(0);
      
      const buyerBalanceAfter = await provider.getBalance(buyer.address);
      expect(buyerBalanceAfter).to.equal(buyerBalanceBefore + depositAmount - gasUsed);
    });

    it("Should refund when seller and mediator approve", async function () {
      const depositAmount = ethers.parseEther("1.0");
      const buyerBalanceBefore = await provider.getBalance(buyer.address);
      
      await escrow.connect(seller).approveRefund();
      await escrow.connect(mediator).approveRefund();
      
      expect(await escrow.fundsRefunded()).to.be.true;
      expect(await escrow.amount()).to.equal(0);
      
      const buyerBalanceAfter = await provider.getBalance(buyer.address);
      expect(buyerBalanceAfter).to.equal(buyerBalanceBefore + depositAmount);
    });
  });

  describe("Edge Cases", function () {
    it("Should prevent operations after funds released", async function () {
      await escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") });
      await escrow.connect(buyer).approveRelease();
      await escrow.connect(seller).approveRelease();
      
      await expect(
        escrow.connect(mediator).approveRelease()
      ).to.be.revertedWith("Funds already released or refunded");
    });

    it("Should prevent operations after funds refunded", async function () {
      await escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") });
      await escrow.connect(buyer).approveRefund();
      await escrow.connect(seller).approveRefund();
      
      await expect(
        escrow.connect(mediator).approveRefund()
      ).to.be.revertedWith("Funds already released or refunded");
    });

    it("Should require deposit before approval", async function () {
      await expect(
        escrow.connect(buyer).approveRelease()
      ).to.be.revertedWith("No funds deposited");
    });
  });

  describe("Get Escrow State", function () {
    it("Should return correct initial state", async function () {
      const state = await escrow.getEscrowState();
      
      expect(state._buyer).to.equal(buyer.address);
      expect(state._seller).to.equal(seller.address);
      expect(state._mediator).to.equal(mediator.address);
      expect(state._amount).to.equal(0);
      expect(state._buyerApprovedRelease).to.be.false;
      expect(state._sellerApprovedRelease).to.be.false;
      expect(state._mediatorApprovedRelease).to.be.false;
      expect(state._buyerApprovedRefund).to.be.false;
      expect(state._sellerApprovedRefund).to.be.false;
      expect(state._mediatorApprovedRefund).to.be.false;
      expect(state._fundsReleased).to.be.false;
      expect(state._fundsRefunded).to.be.false;
    });

    it("Should return correct state after deposit and approvals", async function () {
      await escrow.connect(buyer).deposit({ value: ethers.parseEther("1.0") });
      await escrow.connect(buyer).approveRelease();
      
      const state = await escrow.getEscrowState();
      
      expect(state._amount).to.equal(ethers.parseEther("1.0"));
      expect(state._buyerApprovedRelease).to.be.true;
      expect(state._fundsReleased).to.be.false;
    });
  });
});

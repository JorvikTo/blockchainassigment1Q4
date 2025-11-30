// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol"; // this import is automatically injected by Remix
import "remix_accounts.sol";
import "../contracts/ThreePartyEscrow.sol";

/**
 * @title ThreePartyEscrow Unit Tests
 * @dev Unit tests for the ThreePartyEscrow contract using Remix testing framework
 */
contract ThreePartyEscrowTest {
    ThreePartyEscrow escrow;
    
    // Test accounts
    address acc0; // buyer
    address acc1; // seller
    address acc2; // mediator
    address acc3; // other (non-party)
    
    /// 'beforeAll' runs before all other tests
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
    }
    
    /// 'beforeEach' runs before each test
    function beforeEach() public {
        escrow = new ThreePartyEscrow(acc0, acc1, acc2);
    }
    
    /// #sender: account-0
    function testDeploymentSetsBuyer() public {
        Assert.equal(escrow.buyer(), acc0, "Buyer should be set correctly");
    }
    
    /// #sender: account-0
    function testDeploymentSetsSeller() public {
        Assert.equal(escrow.seller(), acc1, "Seller should be set correctly");
    }
    
    /// #sender: account-0
    function testDeploymentSetsMediator() public {
        Assert.equal(escrow.mediator(), acc2, "Mediator should be set correctly");
    }
    
    /// #sender: account-0
    function testDeploymentRejectsZeroBuyer() public {
        try new ThreePartyEscrow(address(0), acc1, acc2) {
            Assert.ok(false, "Should reject zero buyer address");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Buyer address cannot be zero", "Should reject with correct error");
        }
    }
    
    /// #sender: account-0
    function testDeploymentRejectsZeroSeller() public {
        try new ThreePartyEscrow(acc0, address(0), acc2) {
            Assert.ok(false, "Should reject zero seller address");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Seller address cannot be zero", "Should reject with correct error");
        }
    }
    
    /// #sender: account-0
    function testDeploymentRejectsZeroMediator() public {
        try new ThreePartyEscrow(acc0, acc1, address(0)) {
            Assert.ok(false, "Should reject zero mediator address");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Mediator address cannot be zero", "Should reject with correct error");
        }
    }
    
    /// #sender: account-0
    function testDeploymentRejectsSameBuyerSeller() public {
        try new ThreePartyEscrow(acc0, acc0, acc2) {
            Assert.ok(false, "Should reject same buyer and seller");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Buyer and seller must be different", "Should reject with correct error");
        }
    }
    
    /// #sender: account-0
    function testDeploymentRejectsSameBuyerMediator() public {
        try new ThreePartyEscrow(acc0, acc1, acc0) {
            Assert.ok(false, "Should reject same buyer and mediator");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Buyer and mediator must be different", "Should reject with correct error");
        }
    }
    
    /// #sender: account-0
    function testDeploymentRejectsSameSellerMediator() public {
        try new ThreePartyEscrow(acc0, acc1, acc1) {
            Assert.ok(false, "Should reject same seller and mediator");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Seller and mediator must be different", "Should reject with correct error");
        }
    }
    
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testBuyerCanDeposit() public payable {
        escrow.deposit{value: 1 ether}();
        Assert.equal(escrow.amount(), 1 ether, "Deposit amount should be recorded");
    }
    
    /// #sender: account-1
    /// #value: 1000000000000000000
    function testOnlyBuyerCanDeposit() public payable {
        try escrow.deposit{value: 1 ether}() {
            Assert.ok(false, "Non-buyer should not be able to deposit");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Only buyer can deposit", "Should reject non-buyer deposit");
        }
    }
    
    /// #sender: account-0
    function testDepositRejectsZeroAmount() public {
        try escrow.deposit{value: 0}() {
            Assert.ok(false, "Should reject zero deposit");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Deposit must be greater than 0", "Should reject zero deposit");
        }
    }
    
    /// #sender: account-0
    /// #value: 2000000000000000000
    function testDepositRejectsDoubleDeposit() public payable {
        escrow.deposit{value: 1 ether}();
        try escrow.deposit{value: 1 ether}() {
            Assert.ok(false, "Should reject double deposit");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Funds already deposited", "Should reject double deposit");
        }
    }
    
    /// #sender: account-0
    function testApprovalRequiresFundsDeposited() public {
        try escrow.approveRelease() {
            Assert.ok(false, "Should require funds deposited before approval");
        } catch Error(string memory reason) {
            Assert.equal(reason, "No funds deposited", "Should require deposit first");
        }
    }
    
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testBuyerCanApproveRelease() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        Assert.ok(escrow.buyerApprovedRelease(), "Buyer approval should be recorded");
    }
    
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testPreventDoubleApproval() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        try escrow.approveRelease() {
            Assert.ok(false, "Should prevent double approval");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Buyer already approved release", "Should reject double approval");
        }
    }
    
    /// #sender: account-3
    /// #value: 1000000000000000000
    function testOnlyPartiesCanApprove() public payable {
        // First deposit as buyer
        ThreePartyEscrow tempEscrow = new ThreePartyEscrow(acc0, acc1, acc2);
        // Send funds to temp escrow from acc0 context is tricky in Remix, so we test rejection
        try tempEscrow.approveRelease() {
            Assert.ok(false, "Non-party should not be able to approve");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Only parties can call this function", "Should reject non-party");
        }
    }
    
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testGetEscrowStatusPending() public payable {
        escrow.deposit{value: 1 ether}();
        string memory status = escrow.getEscrowStatus();
        Assert.equal(status, "Pending", "Status should be Pending with no approvals");
    }
    
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testBuyerCanApproveRefund() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRefund();
        Assert.ok(escrow.buyerApprovedRefund(), "Buyer refund approval should be recorded");
    }
    
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testPreventDoubleRefundApproval() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRefund();
        try escrow.approveRefund() {
            Assert.ok(false, "Should prevent double refund approval");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Buyer already approved refund", "Should reject double refund approval");
        }
    }
}

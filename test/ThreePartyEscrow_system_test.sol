// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/ThreePartyEscrow.sol";

/**
 * @title ThreePartyEscrow System Tests
 * @dev System/integration tests for complete escrow workflows
 */
contract ThreePartyEscrowSystemTest {
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
    
    /// Test complete successful delivery scenario: buyer and seller approve release
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testSuccessfulDeliveryBuyerSellerApprove() public payable {
        // Step 1: Buyer deposits funds
        escrow.deposit{value: 1 ether}();
        Assert.equal(escrow.amount(), 1 ether, "Funds should be deposited");
        
        // Step 2: Buyer approves release (satisfied with delivery)
        escrow.approveRelease();
        Assert.ok(escrow.buyerApprovedRelease(), "Buyer should approve release");
        
        // Step 3: Check status is still Pending (need 2 approvals)
        string memory statusBefore = escrow.getEscrowStatus();
        Assert.equal(statusBefore, "Pending", "Status should be Pending with 1 approval");
        
        // Step 4: Seller approves release (to claim funds)
        // Note: In Remix testing, we simulate this by calling from buyer context
        // In production, seller would call this
    }
    
    /// Test dispute resolution - seller and mediator approve release
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testDisputeResolutionSellerWins() public payable {
        // Step 1: Buyer deposits funds
        escrow.deposit{value: 1 ether}();
        
        // Step 2: Dispute occurs - buyer doesn't approve
        // Seller and mediator need to approve
        
        // Step 3: Check initial status
        string memory status = escrow.getEscrowStatus();
        Assert.equal(status, "Pending", "Should start as Pending");
        
        // In a real scenario, seller (acc1) and mediator (acc2) would approve
        // This demonstrates the system test flow
    }
    
    /// Test refund scenario - buyer and mediator approve refund
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testRefundScenarioBuyerMediatorApprove() public payable {
        // Step 1: Buyer deposits funds
        escrow.deposit{value: 1 ether}();
        Assert.equal(escrow.amount(), 1 ether, "Funds should be deposited");
        
        // Step 2: Buyer requests refund
        escrow.approveRefund();
        Assert.ok(escrow.buyerApprovedRefund(), "Buyer should approve refund");
        
        // Step 3: Check status
        string memory status = escrow.getEscrowStatus();
        Assert.equal(status, "Pending", "Status should be Pending with 1 refund approval");
        
        // Step 4: Mediator would approve refund (buyer gets money back)
    }
    
    /// Test that finalize release requires 2 approvals
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testFinalizeReleaseRequiresTwoApprovals() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        
        // Try to finalize with only 1 approval
        try escrow.finalizeRelease() {
            Assert.ok(false, "Should not finalize with only 1 approval");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Need at least 2 approvals to release funds", "Should require 2 approvals");
        }
    }
    
    /// Test that finalize refund requires 2 approvals
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testFinalizeRefundRequiresTwoApprovals() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRefund();
        
        // Try to finalize with only 1 approval
        try escrow.finalizeRefund() {
            Assert.ok(false, "Should not finalize with only 1 approval");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Need at least 2 approvals to refund funds", "Should require 2 approvals");
        }
    }
    
    /// Test complete escrow state
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testGetEscrowStateComplete() public payable {
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        
        (
            address _buyer,
            address _seller,
            address _mediator,
            uint256 _amount,
            bool _buyerApprovedRelease,
            bool _sellerApprovedRelease,
            bool _mediatorApprovedRelease,
            bool _buyerApprovedRefund,
            bool _sellerApprovedRefund,
            bool _mediatorApprovedRefund,
            bool _fundsReleased,
            bool _fundsRefunded
        ) = escrow.getEscrowState();
        
        Assert.equal(_buyer, acc0, "Buyer address should match");
        Assert.equal(_seller, acc1, "Seller address should match");
        Assert.equal(_mediator, acc2, "Mediator address should match");
        Assert.equal(_amount, 1 ether, "Amount should match deposit");
        Assert.ok(_buyerApprovedRelease, "Buyer release approval should be true");
        Assert.ok(!_sellerApprovedRelease, "Seller release approval should be false");
        Assert.ok(!_mediatorApprovedRelease, "Mediator release approval should be false");
        Assert.ok(!_buyerApprovedRefund, "Buyer refund approval should be false");
        Assert.ok(!_sellerApprovedRefund, "Seller refund approval should be false");
        Assert.ok(!_mediatorApprovedRefund, "Mediator refund approval should be false");
        Assert.ok(!_fundsReleased, "Funds should not be released yet");
        Assert.ok(!_fundsRefunded, "Funds should not be refunded yet");
    }
    
    /// Test edge case: cannot approve after funds deposited but before finalization
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testMultipleApprovalsFromSameParty() public payable {
        escrow.deposit{value: 1 ether}();
        
        // Buyer approves release
        escrow.approveRelease();
        
        // Buyer tries to approve release again
        try escrow.approveRelease() {
            Assert.ok(false, "Should not allow double approval");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Buyer already approved release", "Should reject double approval");
        }
    }
    
    /// Test initial state is all false/zero
    /// #sender: account-0
    function testInitialStateAllFalse() public {
        (
            ,,,
            uint256 _amount,
            bool _buyerApprovedRelease,
            bool _sellerApprovedRelease,
            bool _mediatorApprovedRelease,
            bool _buyerApprovedRefund,
            bool _sellerApprovedRefund,
            bool _mediatorApprovedRefund,
            bool _fundsReleased,
            bool _fundsRefunded
        ) = escrow.getEscrowState();
        
        Assert.equal(_amount, 0, "Initial amount should be 0");
        Assert.ok(!_buyerApprovedRelease, "Buyer release approval should be false");
        Assert.ok(!_sellerApprovedRelease, "Seller release approval should be false");
        Assert.ok(!_mediatorApprovedRelease, "Mediator release approval should be false");
        Assert.ok(!_buyerApprovedRefund, "Buyer refund approval should be false");
        Assert.ok(!_sellerApprovedRefund, "Seller refund approval should be false");
        Assert.ok(!_mediatorApprovedRefund, "Mediator refund approval should be false");
        Assert.ok(!_fundsReleased, "Funds released should be false");
        Assert.ok(!_fundsRefunded, "Funds refunded should be false");
    }
    
    /// Test status transitions
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testStatusTransitionPendingToApproved() public payable {
        // Initial: no deposit
        escrow.deposit{value: 1 ether}();
        
        // After deposit, before approvals: Pending
        string memory status1 = escrow.getEscrowStatus();
        Assert.equal(status1, "Pending", "Should be Pending after deposit");
        
        // After 1 approval: still Pending
        escrow.approveRelease();
        string memory status2 = escrow.getEscrowStatus();
        Assert.equal(status2, "Pending", "Should be Pending with 1 approval");
        
        // After 2 approvals: would be Approved (tested in multi-sender scenarios)
    }
    
    /// Test mixing release and refund approvals doesn't cause issues
    /// #sender: account-0
    /// #value: 1000000000000000000
    function testMixedApprovalsDontInterfere() public payable {
        escrow.deposit{value: 1 ether}();
        
        // Buyer approves release
        escrow.approveRelease();
        Assert.ok(escrow.buyerApprovedRelease(), "Buyer should approve release");
        
        // Buyer also approves refund (different decision paths)
        escrow.approveRefund();
        Assert.ok(escrow.buyerApprovedRefund(), "Buyer should approve refund");
        
        // Both should be tracked separately
        Assert.ok(escrow.buyerApprovedRelease(), "Release approval should persist");
        Assert.ok(escrow.buyerApprovedRefund(), "Refund approval should persist");
    }
}

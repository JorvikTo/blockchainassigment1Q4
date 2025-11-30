// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/ThreePartyEscrow.sol";

/**
 * @title ThreePartyEscrowTestRunner
 * @dev Executable test contract with actual implementations that can run and verify
 * This contract contains executable unit and integration tests for the ThreePartyEscrow
 */
contract ThreePartyEscrowTestRunner {
    
    // Test state
    uint256 public testsPassed;
    uint256 public testsFailed;
    uint256 public testsTotal;
    
    // Test accounts (simulated)
    address payable public testBuyer;
    address payable public testSeller;
    address payable public testMediator;
    address payable public testUnauthorized;
    
    // Events for test results
    event TestResult(string testName, bool passed, string message);
    event TestSuiteComplete(uint256 total, uint256 passed, uint256 failed);
    
    constructor() payable {
        // Initialize test accounts with distinct addresses
        testBuyer = payable(address(uint160(uint256(keccak256("buyer")))));
        testSeller = payable(address(uint160(uint256(keccak256("seller")))));
        testMediator = payable(address(uint160(uint256(keccak256("mediator")))));
        testUnauthorized = payable(address(uint160(uint256(keccak256("unauthorized")))));
    }
    
    /**
     * @dev Helper to check test result
     */
    function recordTest(string memory testName, bool passed, string memory message) internal {
        testsTotal++;
        if (passed) {
            testsPassed++;
            emit TestResult(testName, true, message);
        } else {
            testsFailed++;
            emit TestResult(testName, false, message);
        }
    }
    
    // ============================================
    // UNIT TESTS: Constructor Validation
    // ============================================
    
    function testConstructorValidAddresses() public {
        ThreePartyEscrow escrow = new ThreePartyEscrow(testBuyer, testSeller, testMediator);
        
        bool passed = escrow.buyer() == testBuyer &&
                      escrow.seller() == testSeller &&
                      escrow.mediator() == testMediator &&
                      escrow.amount() == 0 &&
                      !escrow.fundsReleased() &&
                      !escrow.fundsRefunded();
        
        recordTest(
            "testConstructorValidAddresses",
            passed,
            passed ? "All constructor validations passed" : "Constructor validation failed"
        );
    }
    
    function testConstructorRejectsZeroBuyer() public {
        bool reverted = false;
        try new ThreePartyEscrow(address(0), testSeller, testMediator) {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Buyer address cannot be zero"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testConstructorRejectsZeroBuyer",
            reverted,
            reverted ? "Correctly rejected zero buyer address" : "Failed to reject zero buyer"
        );
    }
    
    function testConstructorRejectsZeroSeller() public {
        bool reverted = false;
        try new ThreePartyEscrow(testBuyer, address(0), testMediator) {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Seller address cannot be zero"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testConstructorRejectsZeroSeller",
            reverted,
            reverted ? "Correctly rejected zero seller address" : "Failed to reject zero seller"
        );
    }
    
    function testConstructorRejectsZeroMediator() public {
        bool reverted = false;
        try new ThreePartyEscrow(testBuyer, testSeller, address(0)) {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Mediator address cannot be zero"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testConstructorRejectsZeroMediator",
            reverted,
            reverted ? "Correctly rejected zero mediator address" : "Failed to reject zero mediator"
        );
    }
    
    function testConstructorRejectsSameBuyerSeller() public {
        bool reverted = false;
        try new ThreePartyEscrow(testBuyer, testBuyer, testMediator) {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Buyer and seller must be different"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testConstructorRejectsSameBuyerSeller",
            reverted,
            reverted ? "Correctly rejected same buyer and seller" : "Failed to reject same buyer/seller"
        );
    }
    
    function testConstructorRejectsSameBuyerMediator() public {
        bool reverted = false;
        try new ThreePartyEscrow(testBuyer, testSeller, testBuyer) {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Buyer and mediator must be different"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testConstructorRejectsSameBuyerMediator",
            reverted,
            reverted ? "Correctly rejected same buyer and mediator" : "Failed to reject same buyer/mediator"
        );
    }
    
    function testConstructorRejectsSameSellerMediator() public {
        bool reverted = false;
        try new ThreePartyEscrow(testBuyer, testSeller, testSeller) {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Seller and mediator must be different"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testConstructorRejectsSameSellerMediator",
            reverted,
            reverted ? "Correctly rejected same seller and mediator" : "Failed to reject same seller/mediator"
        );
    }
    
    // ============================================
    // UNIT TESTS: State Verification
    // ============================================
    
    function testGetEscrowStateInitial() public {
        ThreePartyEscrow escrow = new ThreePartyEscrow(testBuyer, testSeller, testMediator);
        
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
        
        bool passed = _buyer == testBuyer &&
                      _seller == testSeller &&
                      _mediator == testMediator &&
                      _amount == 0 &&
                      !_buyerApprovedRelease &&
                      !_sellerApprovedRelease &&
                      !_mediatorApprovedRelease &&
                      !_buyerApprovedRefund &&
                      !_sellerApprovedRefund &&
                      !_mediatorApprovedRefund &&
                      !_fundsReleased &&
                      !_fundsRefunded;
        
        recordTest(
            "testGetEscrowStateInitial",
            passed,
            passed ? "Initial state is correct" : "Initial state verification failed"
        );
    }
    
    // ============================================
    // SYSTEM TEST: Complete Transaction Flow
    // ============================================
    
    /**
     * @dev This helper contract acts as the buyer for testing
     */
    function testSystemFlow() public payable {
        // Create escrow where this contract is the buyer
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        // Test deposit
        uint256 depositAmount = 1 ether;
        require(address(this).balance >= depositAmount, "Insufficient balance for test");
        
        escrow.deposit{value: depositAmount}();
        
        bool depositPassed = escrow.amount() == depositAmount;
        recordTest(
            "testSystemFlow_Deposit",
            depositPassed,
            depositPassed ? "Deposit successful" : "Deposit failed"
        );
        
        // Test that escrow status is Pending
        string memory status = escrow.getEscrowStatus();
        bool statusPassed = keccak256(bytes(status)) == keccak256(bytes("Pending"));
        recordTest(
            "testSystemFlow_StatusPending",
            statusPassed,
            statusPassed ? "Status is Pending" : "Status is not Pending"
        );
        
        // Buyer approves release (this contract is buyer)
        escrow.approveRelease();
        bool buyerApprovalPassed = escrow.buyerApprovedRelease();
        recordTest(
            "testSystemFlow_BuyerApproval",
            buyerApprovalPassed,
            buyerApprovalPassed ? "Buyer approval recorded" : "Buyer approval failed"
        );
        
        // Still pending with only 1 approval
        status = escrow.getEscrowStatus();
        bool stillPending = keccak256(bytes(status)) == keccak256(bytes("Pending"));
        recordTest(
            "testSystemFlow_StillPendingWith1Approval",
            stillPending,
            stillPending ? "Status still Pending with 1 approval" : "Status changed incorrectly"
        );
    }
    
    /**
     * @dev Test that contract reverts on double deposit
     */
    function testDoubleDepositReverts() public payable {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        // First deposit
        escrow.deposit{value: 0.5 ether}();
        
        // Try second deposit
        bool reverted = false;
        try escrow.deposit{value: 0.5 ether}() {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Funds already deposited"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testDoubleDepositReverts",
            reverted,
            reverted ? "Correctly prevented double deposit" : "Failed to prevent double deposit"
        );
    }
    
    /**
     * @dev Test zero deposit is rejected
     */
    function testZeroDepositReverts() public {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        bool reverted = false;
        try escrow.deposit{value: 0}() {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Deposit must be greater than 0"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testZeroDepositReverts",
            reverted,
            reverted ? "Correctly rejected zero deposit" : "Failed to reject zero deposit"
        );
    }
    
    /**
     * @dev Test approving release without deposit fails
     */
    function testApproveReleaseWithoutDepositReverts() public {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        bool reverted = false;
        try escrow.approveRelease() {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("No funds deposited"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testApproveReleaseWithoutDepositReverts",
            reverted,
            reverted ? "Correctly rejected approval without deposit" : "Failed to reject approval without deposit"
        );
    }
    
    /**
     * @dev Test double approval from same party fails
     */
    function testDoubleApprovalReverts() public payable {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        // Deposit first
        escrow.deposit{value: 1 ether}();
        
        // First approval
        escrow.approveRelease();
        
        // Try second approval
        bool reverted = false;
        try escrow.approveRelease() {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Buyer already approved release"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testDoubleApprovalReverts",
            reverted,
            reverted ? "Correctly prevented double approval" : "Failed to prevent double approval"
        );
    }
    
    /**
     * @dev Test that finalizing with only 1 approval fails
     */
    function testFinalizeWithOneApprovalReverts() public payable {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        // Deposit and one approval
        escrow.deposit{value: 1 ether}();
        escrow.approveRelease();
        
        // Try to finalize with only 1 approval
        bool reverted = false;
        try escrow.finalizeRelease() {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Need at least 2 approvals to release funds"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testFinalizeWithOneApprovalReverts",
            reverted,
            reverted ? "Correctly rejected finalize with 1 approval" : "Failed to reject premature finalize"
        );
    }
    
    /**
     * @dev Test refund approval tracking
     */
    function testRefundApprovalTracking() public payable {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        // Deposit
        escrow.deposit{value: 1 ether}();
        
        // Approve refund
        escrow.approveRefund();
        
        bool passed = escrow.buyerApprovedRefund() &&
                      !escrow.buyerApprovedRelease();
        
        recordTest(
            "testRefundApprovalTracking",
            passed,
            passed ? "Refund approval tracked separately" : "Refund approval tracking failed"
        );
    }
    
    /**
     * @dev Test that finalizing refund with one approval fails
     */
    function testFinalizeRefundWithOneApprovalReverts() public payable {
        ThreePartyEscrow escrow = new ThreePartyEscrow(address(this), testSeller, testMediator);
        
        // Deposit and one refund approval
        escrow.deposit{value: 1 ether}();
        escrow.approveRefund();
        
        // Try to finalize with only 1 approval
        bool reverted = false;
        try escrow.finalizeRefund() {
            // Should not reach here
        } catch Error(string memory reason) {
            reverted = keccak256(bytes(reason)) == keccak256(bytes("Need at least 2 approvals to refund funds"));
        } catch {
            reverted = false;
        }
        
        recordTest(
            "testFinalizeRefundWithOneApprovalReverts",
            reverted,
            reverted ? "Correctly rejected refund finalize with 1 approval" : "Failed to reject premature refund"
        );
    }
    
    // ============================================
    // TEST RUNNER
    // ============================================
    
    /**
     * @dev Run all executable tests
     */
    function runAllTests() external payable {
        // Reset counters
        testsPassed = 0;
        testsFailed = 0;
        testsTotal = 0;
        
        // Constructor tests
        testConstructorValidAddresses();
        testConstructorRejectsZeroBuyer();
        testConstructorRejectsZeroSeller();
        testConstructorRejectsZeroMediator();
        testConstructorRejectsSameBuyerSeller();
        testConstructorRejectsSameBuyerMediator();
        testConstructorRejectsSameSellerMediator();
        
        // State tests
        testGetEscrowStateInitial();
        
        // Deposit tests (require funding)
        if (address(this).balance >= 5 ether) {
            testSystemFlow();
            testDoubleDepositReverts();
            testZeroDepositReverts();
            testApproveReleaseWithoutDepositReverts();
            testDoubleApprovalReverts();
            testFinalizeWithOneApprovalReverts();
            testRefundApprovalTracking();
            testFinalizeRefundWithOneApprovalReverts();
        }
        
        emit TestSuiteComplete(testsTotal, testsPassed, testsFailed);
    }
    
    /**
     * @dev Get test summary
     */
    function getTestSummary() external view returns (uint256 total, uint256 passed, uint256 failed, uint256 passRate) {
        total = testsTotal;
        passed = testsPassed;
        failed = testsFailed;
        if (total > 0) {
            passRate = (passed * 100) / total;
        } else {
            passRate = 0;
        }
    }
    
    // Allow contract to receive ETH for testing
    receive() external payable {}
}

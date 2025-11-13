// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ThreePartyEscrow
 * @dev A three-party escrow contract where funds are released only when 2 out of 3 parties approve.
 * The three parties are: buyer, seller, and mediator.
 * Uses ERC standard practices for secure fund handling and event tracking.
 */
contract ThreePartyEscrow {
    // State variables for participant roles
    address public buyer;
    address public seller;
    address public mediator;
    
    // Escrow deposit amount
    uint256 public amount;
    
    // Approval tracking for release
    bool public buyerApprovedRelease;
    bool public sellerApprovedRelease;
    bool public mediatorApprovedRelease;
    
    // Approval tracking for refund
    bool public buyerApprovedRefund;
    bool public sellerApprovedRefund;
    bool public mediatorApprovedRefund;
    
    // State flags
    bool public fundsReleased;
    bool public fundsRefunded;
    
    // Events for external auditing and tracking
    event FundsDeposited(address indexed buyer, uint256 amount);
    event ApprovalGiven(address indexed approver);
    event FundsReleased(address indexed seller, uint256 amount);
    event FundsRefunded(address indexed buyer, uint256 amount);
    
    // Modifier to restrict function access to the three parties only
    modifier onlyParty() {
        require(
            msg.sender == buyer || msg.sender == seller || msg.sender == mediator,
            "Only parties can call this function"
        );
        _;
    }
    
    // Modifier to prevent operations after funds have been released or refunded
    modifier fundsNotReleased() {
        require(!fundsReleased && !fundsRefunded, "Funds already released or refunded");
        _;
    }
    
    /**
     * @dev Constructor to initialize the escrow contract with participant roles
     * @param _buyer Address of the buyer
     * @param _seller Address of the seller
     * @param _mediator Address of the mediator
     */
    constructor(address _buyer, address _seller, address _mediator) {
        // Validate that no address is zero
        require(_buyer != address(0), "Buyer address cannot be zero");
        require(_seller != address(0), "Seller address cannot be zero");
        require(_mediator != address(0), "Mediator address cannot be zero");
        
        // Ensure all three parties are different addresses
        require(_buyer != _seller, "Buyer and seller must be different");
        require(_buyer != _mediator, "Buyer and mediator must be different");
        require(_seller != _mediator, "Seller and mediator must be different");
        
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
    }
    
    /**
     * @dev Buyer sends Ether to the contract to lock funds on-chain
     * Value stored as escrow deposit
     */
    function deposit() external payable {
        // Only buyer can deposit funds
        require(msg.sender == buyer, "Only buyer can deposit");
        
        // Deposit must be a positive amount
        require(msg.value > 0, "Deposit must be greater than 0");
        
        // Prevent double deposits - fail-safe design
        require(amount == 0, "Funds already deposited");
        
        amount = msg.value;
        emit FundsDeposited(buyer, amount);
    }
    
    /**
     * @dev Logs approval from one of the three permitted parties
     * Increments total approvals and prevents re-approvals by the same party
     * Each party can only approve once - fail-safe design
     */
    function approveRelease() external onlyParty fundsNotReleased {
        // Require that funds have been deposited before approval
        require(amount > 0, "No funds deposited");
        
        // Track approval based on caller and prevent double-approval
        if (msg.sender == buyer) {
            require(!buyerApprovedRelease, "Buyer already approved release");
            buyerApprovedRelease = true;
        } else if (msg.sender == seller) {
            require(!sellerApprovedRelease, "Seller already approved release");
            sellerApprovedRelease = true;
        } else if (msg.sender == mediator) {
            require(!mediatorApprovedRelease, "Mediator already approved release");
            mediatorApprovedRelease = true;
        }
        
        // Emit event for external auditing
        emit ApprovalGiven(msg.sender);
    }
    
    /**
     * @dev Transfers locked funds to seller once at least two unique approvals exist
     * Implements consensus release - prevents double-payouts
     */
    function finalizeRelease() external onlyParty fundsNotReleased {
        // Require funds to be deposited
        require(amount > 0, "No funds deposited");
        
        // Check if we have 2 out of 3 approvals for release
        uint8 approvalCount = _countReleaseApprovals();
        require(approvalCount >= 2, "Need at least 2 approvals to release funds");
        
        _releaseFunds();
    }
    
    /**
     * @dev Returns current escrow state for monitoring
     * @return status Current state: "Pending", "Approved", or "Funds Released"
     */
    function getEscrowStatus() external view returns (string memory) {
        // If funds have been released or refunded
        if (fundsReleased) {
            return "Funds Released";
        }
        if (fundsRefunded) {
            return "Funds Refunded";
        }
        
        // If we have at least 2 approvals for release
        if (_countReleaseApprovals() >= 2) {
            return "Approved";
        }
        
        // If we have at least 2 approvals for refund
        if (_countRefundApprovals() >= 2) {
            return "Approved";
        }
        
        // Default state when no consensus reached
        return "Pending";
    }
    
    /**
     * @dev Any party can approve a refund to the buyer
     */
    function approveRefund() external onlyParty fundsNotReleased {
        require(amount > 0, "No funds deposited");
        
        if (msg.sender == buyer) {
            require(!buyerApprovedRefund, "Buyer already approved refund");
            buyerApprovedRefund = true;
        } else if (msg.sender == seller) {
            require(!sellerApprovedRefund, "Seller already approved refund");
            sellerApprovedRefund = true;
        } else if (msg.sender == mediator) {
            require(!mediatorApprovedRefund, "Mediator already approved refund");
            mediatorApprovedRefund = true;
        }
        
        emit ApprovalGiven(msg.sender);
    }
    
    /**
     * @dev Finalize refund to buyer once at least two unique approvals exist
     */
    function finalizeRefund() external onlyParty fundsNotReleased {
        require(amount > 0, "No funds deposited");
        
        // Check if we have 2 out of 3 approvals for refund
        uint8 approvalCount = _countRefundApprovals();
        require(approvalCount >= 2, "Need at least 2 approvals to refund funds");
        
        _refundFunds();
    }
    
    /**
     * @dev Internal function to count release approvals
     * @return count Number of release approvals
     */
    function _countReleaseApprovals() private view returns (uint8 count) {
        if (buyerApprovedRelease) count++;
        if (sellerApprovedRelease) count++;
        if (mediatorApprovedRelease) count++;
        return count;
    }
    
    /**
     * @dev Internal function to count refund approvals
     * @return count Number of refund approvals
     */
    function _countRefundApprovals() private view returns (uint8 count) {
        if (buyerApprovedRefund) count++;
        if (sellerApprovedRefund) count++;
        if (mediatorApprovedRefund) count++;
        return count;
    }
    
    /**
     * @dev Internal function to release funds to seller
     * Uses checks-effects-interactions pattern for security
     */
    function _releaseFunds() private {
        require(amount > 0, "No funds to release");
        require(!fundsReleased, "Funds already released");
        
        // Update state before external call (checks-effects-interactions)
        fundsReleased = true;
        uint256 amountToRelease = amount;
        amount = 0;
        
        // Transfer funds to seller
        (bool success, ) = seller.call{value: amountToRelease}("");
        require(success, "Transfer to seller failed");
        
        // Emit event for external auditing
        emit FundsReleased(seller, amountToRelease);
    }
    
    /**
     * @dev Internal function to refund funds to buyer
     * Uses checks-effects-interactions pattern for security
     */
    function _refundFunds() private {
        require(amount > 0, "No funds to refund");
        require(!fundsRefunded, "Funds already refunded");
        
        // Update state before external call (checks-effects-interactions)
        fundsRefunded = true;
        uint256 amountToRefund = amount;
        amount = 0;
        
        // Transfer funds to buyer
        (bool success, ) = buyer.call{value: amountToRefund}("");
        require(success, "Transfer to buyer failed");
        
        // Emit event for external auditing
        emit FundsRefunded(buyer, amountToRefund);
    }
    
    /**
     * @dev Get the current state of the escrow
     */
    function getEscrowState() external view returns (
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
    ) {
        return (
            buyer,
            seller,
            mediator,
            amount,
            buyerApprovedRelease,
            sellerApprovedRelease,
            mediatorApprovedRelease,
            buyerApprovedRefund,
            sellerApprovedRefund,
            mediatorApprovedRefund,
            fundsReleased,
            fundsRefunded
        );
    }
}

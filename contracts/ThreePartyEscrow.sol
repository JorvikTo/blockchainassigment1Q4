// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ThreePartyEscrow
 * @dev A three-party escrow contract where funds are released only when 2 out of 3 parties approve.
 * The three parties are: buyer, seller, and mediator.
 */
contract ThreePartyEscrow {
    address public buyer;
    address public seller;
    address public mediator;
    uint256 public amount;
    
    bool public buyerApprovedRelease;
    bool public sellerApprovedRelease;
    bool public mediatorApprovedRelease;
    
    bool public buyerApprovedRefund;
    bool public sellerApprovedRefund;
    bool public mediatorApprovedRefund;
    
    bool public fundsReleased;
    bool public fundsRefunded;
    
    event FundsDeposited(address indexed buyer, uint256 amount);
    event ApprovalGiven(address indexed approver);
    event FundsReleased(address indexed seller, uint256 amount);
    event FundsRefunded(address indexed buyer, uint256 amount);
    
    modifier onlyParty() {
        require(
            msg.sender == buyer || msg.sender == seller || msg.sender == mediator,
            "Only parties can call this function"
        );
        _;
    }
    
    modifier fundsNotReleased() {
        require(!fundsReleased && !fundsRefunded, "Funds already released or refunded");
        _;
    }
    
    /**
     * @dev Constructor to initialize the escrow contract
     * @param _seller Address of the seller
     * @param _mediator Address of the mediator
     */
    constructor(address _seller, address _mediator) {
        require(_seller != address(0), "Seller address cannot be zero");
        require(_mediator != address(0), "Mediator address cannot be zero");
        require(_seller != _mediator, "Seller and mediator must be different");
        
        buyer = msg.sender;
        seller = _seller;
        mediator = _mediator;
    }
    
    /**
     * @dev Buyer deposits funds into escrow
     */
    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(msg.value > 0, "Deposit must be greater than 0");
        require(amount == 0, "Funds already deposited");
        
        amount = msg.value;
        emit FundsDeposited(buyer, amount);
    }
    
    /**
     * @dev Any party can approve the release of funds to the seller
     */
    function approveRelease() external onlyParty fundsNotReleased {
        require(amount > 0, "No funds deposited");
        
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
        
        emit ApprovalGiven(msg.sender);
        
        // Check if we have 2 out of 3 approvals for release
        if (_countReleaseApprovals() >= 2) {
            _releaseFunds();
        }
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
        
        // Check if we have 2 out of 3 approvals for refund
        if (_countRefundApprovals() >= 2) {
            _refundFunds();
        }
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
     */
    function _releaseFunds() private {
        require(amount > 0, "No funds to release");
        require(!fundsReleased, "Funds already released");
        
        fundsReleased = true;
        uint256 amountToRelease = amount;
        amount = 0;
        
        (bool success, ) = seller.call{value: amountToRelease}("");
        require(success, "Transfer to seller failed");
        
        emit FundsReleased(seller, amountToRelease);
    }
    
    /**
     * @dev Internal function to refund funds to buyer
     */
    function _refundFunds() private {
        require(amount > 0, "No funds to refund");
        require(!fundsRefunded, "Funds already refunded");
        
        fundsRefunded = true;
        uint256 amountToRefund = amount;
        amount = 0;
        
        (bool success, ) = buyer.call{value: amountToRefund}("");
        require(success, "Transfer to buyer failed");
        
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

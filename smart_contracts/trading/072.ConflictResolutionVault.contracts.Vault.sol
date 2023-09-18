//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Vault is ReentrancyGuard, AccessControl {
    
    event OrderCreated(uint8 indexed orderId, uint64 indexed orderTime, OrderStatus indexed status);
    event OrderCancelled(uint8 indexed orderId, uint64 indexed orderTime, OrderStatus indexed status);
    event OrderDelivered(uint8 indexed orderId, uint64 indexed orderTime, OrderStatus indexed status);
    event ConflictStarted(uint8 indexed conflictId, uint64 indexed conflictTime, ConflictStatus indexed status);

    /// @note remember to gas optimize later
    enum OrderStatus{
        PROPOSED,
        ACTIVE,
        ORDER_DELIVERED,
        ORDER_COMPLETE,        
        CONFLICT,
        CANCELLED
    }
    enum ConflictStatus{
        NO_CONFLICT,
        CONFLICT_IN_PROGRESS,
        CONFLICT_SETTLED_FOR_SELLER,
        CONFLICT_SETTLED_FOR_BUYER,
        CONFLICT_CANCELLED
    }
    struct Order{
        uint8 id;
        uint64 timeOfOrder;
        uint64 deliveryTime;
        OrderStatus status;
        uint256 promisedAmount;
        uint256 paidAmount;
        string termsOfCompletion;
        uint256 conflictPremium;
        bytes32 juryRoot;
        uint64 juryNum;
    
    }

    struct Conflict{
        uint8 conflictId;
        ConflictStatus status;
        uint64 conflictStartTime;
        string sellerProof;
        string buyerProof;    
        uint64 sellerVotes;
        uint64 buyerVotes;    
    }

    uint8 public nextOrderId = 0;
    uint32 public constant conflictTimePeriod = 12 hours;
    uint32 public constant resolutionTimePeriod  = 72 hours;

    address payable immutable seller;
    address payable immutable buyer; 
    bytes32 public constant SELLER_ROLE = keccak256("SELLER");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER");
    mapping(uint8 => Order) public orders;
    mapping(uint8 => Conflict) public conflicts;


    constructor(address payable _seller, address payable _buyer) {
        seller = _seller;
        buyer = _buyer;
        _setupRole(SELLER_ROLE, _seller);
        _setupRole(BUYER_ROLE, _buyer);
    }

    function startNewOrder(string calldata termsURI, uint256 _conflictPremium, bytes32 _juryRoot, uint64 _juryNum) public payable onlyRole(BUYER_ROLE){
        Order storage newOrder = orders[nextOrderId];
        newOrder.id = nextOrderId;
        newOrder.timeOfOrder = uint64(block.timestamp);
        newOrder.status = OrderStatus.PROPOSED;
        newOrder.promisedAmount = msg.value - _conflictPremium;
        newOrder.paidAmount = 0;
        newOrder.termsOfCompletion = termsURI;
        newOrder.conflictPremium = _conflictPremium;
        newOrder.juryRoot = _juryRoot;
        newOrder.juryNum = _juryNum;

        emit OrderCreated(nextOrderId, uint64(block.timestamp), OrderStatus.PROPOSED);
        nextOrderId++;
    }

    ///@dev Should be 12 hours after delivery time
    function confirmPayout(uint8 orderId) public onlyRole(SELLER_ROLE){
        require(orders[orderId].status == OrderStatus.ORDER_DELIVERED, "Order must be delivered before payout");
        require(orders[orderId].deliveryTime + conflictTimePeriod < block.timestamp);
        orders[orderId].paidAmount = orders[orderId].promisedAmount;
        orders[orderId].status = OrderStatus.ORDER_COMPLETE;
        seller.transfer(orders[orderId].promisedAmount);        
    }

    

    function deliverAndRequestPayout(uint8 orderId) public onlyRole(SELLER_ROLE){
        require(orders[orderId].status == OrderStatus.ACTIVE, "Order must be in ACTIVE state");
        orders[orderId].status = OrderStatus.ORDER_DELIVERED;
        orders[orderId].deliveryTime = uint64(block.timestamp);
        emit OrderDelivered(orderId, uint64(block.timestamp), OrderStatus.ORDER_DELIVERED);         
    }

    function lodgeConflict(uint8 orderId, string memory conflictURI) public onlyRole(BUYER_ROLE){
        require(orders[orderId].status == OrderStatus.ORDER_DELIVERED, "Order must be delivered before conflict");
        require(orders[orderId].deliveryTime + conflictTimePeriod > block.timestamp);
        Conflict storage newConflict = conflicts[orderId];
        newConflict.conflictId = orderId;
        newConflict.status = ConflictStatus.CONFLICT_IN_PROGRESS;
        newConflict.buyerProof = conflictURI;
        newConflict.conflictStartTime = uint64(block.timestamp);
        emit ConflictStarted(orderId,uint64(block.timestamp), ConflictStatus.CONFLICT_IN_PROGRESS);       
    }


    function acceptOrder(uint8 orderId) public payable onlyRole(SELLER_ROLE){
        require(orders[orderId].status == OrderStatus.PROPOSED, "Order must be in PROPOSED state");
        require(msg.value >= orders[orderId].conflictPremium, "Conflict Premium Insufficient");
        orders[orderId].status = OrderStatus.ACTIVE;
    }

    ///@param vote 0 for seller, 1 for buyer
    ///@param conflictId conflictId is always the same as orderId
    function voteOnConflict(uint8 conflictId, bool vote, bytes32[] calldata addressProof) public{
        require(orders[conflictId].status == OrderStatus.CONFLICT, "Order must be in CONFLICT state");
        require(block.timestamp < conflicts[conflictId].conflictStartTime + resolutionTimePeriod, "Resolution Time Is Over");
        require(conflicts[conflictId].status == ConflictStatus.CONFLICT_IN_PROGRESS, "Conflict must be in CONFLICT_IN_PROGRESS state");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(addressProof, orders[conflictId].juryRoot, leaf), "Address is not valid");
        if(vote){
            conflicts[conflictId].sellerVotes++;
        }
        else{
            conflicts[conflictId].buyerVotes++;
        }
        uint payoutAmount = 2 * orders[conflictId].conflictPremium/ orders[conflictId].juryNum;
        payable(address(msg.sender)).transfer(payoutAmount);

    }

    function provideConflictProofBuyer(uint8 conflictId,string memory conflictURI) public onlyRole(BUYER_ROLE){
        conflicts[conflictId].buyerProof = conflictURI;
    }
    function provideConflictProofSeller(uint8 conflictId,string memory conflictURI) public onlyRole(SELLER_ROLE){
        conflicts[conflictId].sellerProof = conflictURI;
    }


    function settleConflict(uint8 orderId) public nonReentrant{
        require(orders[orderId].status == OrderStatus.CONFLICT, "Order must be in CONFLICT state");
        require(block.timestamp > conflicts[orderId].conflictStartTime + resolutionTimePeriod, "Resolution Time Is Not Over Yet");
        bool result = conflicts[orderId].sellerVotes > conflicts[orderId].buyerVotes;
        
        if(result){
            orders[orderId].paidAmount = orders[orderId].promisedAmount;
            orders[orderId].status = OrderStatus.ORDER_COMPLETE;
            conflicts[orderId].status = ConflictStatus.CONFLICT_SETTLED_FOR_SELLER;
            seller.transfer(orders[orderId].promisedAmount);

        }
        else{
            orders[orderId].paidAmount = 0;
            orders[orderId].status = OrderStatus.CANCELLED;
            conflicts[orderId].status = ConflictStatus.CONFLICT_SETTLED_FOR_BUYER;
            buyer.transfer(orders[orderId].promisedAmount);
        }
    }

}

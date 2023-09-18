// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Mutex.sol";

/**
 * @dev Order info data structure
 * @param orderId The identifier of the order, incrementing uint256 starting from 0
 * @param orderState The state of the order, 1 is open, 2 is filled, 3 is canceled
 * @param tokenId The token id placed in the order
 * @param quoteToken The address of smart contract for ERC20 token that will be used for auction
 * @param minPrice The reserve price for order
 * @param endTime The end time of the auction
 * @param seller The address of seller who created the order
 * @param bids The number of bids placed on the order
 * @param lastBidder The address of the last bidder who bids on the order
 * @param lastBid The last bid price for the order(the highest bid price)
 * @param createTime The timestamp of the order creation
 * @param updateTime The timestamp of last order info update
 */
struct OrderInfo {
    uint256 orderId;
    uint256 orderState;
    uint256 tokenId;
    address quoteToken;
    uint256 minPrice;
    uint256 endTime;
    address seller;
    address buyer;
    uint256 bids;
    address lastBidder;
    uint256 lastBid;
    uint256 createTime;
    uint256 updateTime;
}

contract Auction is Ownable, Mutex {
    OrderInfo[] orders;
    uint256[] openOrders;
    mapping(uint256 => uint256) openOrderToIndex;

    address collection;
    uint increment;
    uint denominator = 100;

    // ----- EVENTS ----- //
    event OrderCreated(uint256 indexed orderId, address seller, uint256 indexed tokenId, address indexed quoteToken, uint256 minPrice, uint256 endTime);
    event OrderBid(uint256 indexed orderId, address indexed bidder, uint256 bid);
    event OrderFilled(uint256 indexed orderId, address seller, address indexed buyer, address indexed quoteToken, uint256 price);
    event OrderCanceled(uint256 indexed orderId, address indexed seller);

    // ----- CONSTRUCTOR ----- //
    constructor(address _collection) {
        collection = _collection;
    }

    // ----- MUTATION FUNCTIONS ----- //
    function createOrder(uint256 _tokenId, address _quoteToken, uint256 _minPrice, uint256 _endTime) external {
        require(_minPrice > 0, "OrderCreate: price cannot be zero");
        require(_endTime > block.timestamp, "OrderCreate: end time is invalid");

        uint256 orderId = _createOrder(_tokenId, _quoteToken, _minPrice, _endTime);
        emit OrderCreated(orderId, _msgSender(), _tokenId, _quoteToken, _minPrice, _endTime);
    }

    function bidOrder(uint256 _orderId, uint256 _value) external nonReentrant {
        require(orders[_orderId].orderState == 1, "OrderBid: invalid order");
        require(orders[_orderId].endTime > block.timestamp, "OrderBid: auction expired");
        require(_value >= orders[_orderId].minPrice, "OrderBid: invalid bid");
        require(_value >= orders[_orderId].lastBid * (denominator + increment) / denominator, "OrderBid: invalid bid");

        _bidOrder(_orderId, _value);
        emit OrderBid(_orderId, _msgSender(), _value);
    }

    function cancelOrder(uint256 _orderId) external {
        require(orders[_orderId].orderState == 1, "OrderCancel: invalid order");
        require(_msgSender() == orders[_orderId].seller, "OrderCancel: caller is not seller");
        require(orders[_orderId].bids == 0, "OrderCancel: auction has already started");

        _cancelOrder(_orderId);
        emit OrderCanceled(_orderId, orders[_orderId].seller);
    }

    function settleOrder(uint256 _orderId) external nonReentrant {
        require(orders[_orderId].orderState == 1, "OrderSettle: invalid order");
        require(orders[_orderId].endTime < block.timestamp, "OrderSettle: auction is not expired");
        require(orders[_orderId].bids > 0, "OrderSettle: auction has not started");

        _settleOrder(_orderId);
        emit OrderFilled(_orderId, orders[_orderId].seller, orders[_orderId].buyer, orders[_orderId].quoteToken, orders[_orderId].lastBid);
    }

    // ----- INTERNAL FUNCTIONS ----- //
    function _createOrder(uint256 _tokenId, address _quoteToken, uint256 _minPrice, uint256 _endTime) internal returns (uint256) {
        IERC721(collection).safeTransferFrom(_msgSender(), address(this), _tokenId);

        OrderInfo memory newOrder;
        newOrder.orderId = orders.length;
        newOrder.orderState = 1;
        newOrder.tokenId = _tokenId;
        newOrder.quoteToken = _quoteToken;
        newOrder.minPrice = _minPrice;
        newOrder.endTime = _endTime;
        newOrder.seller = _msgSender();
        newOrder.createTime = block.timestamp;
        newOrder.updateTime = block.timestamp;

        orders.push(newOrder);
        openOrderToIndex[newOrder.orderId] = openOrders.length;
        openOrders.push(newOrder.orderId);

        return newOrder.orderId;
    }

    function _bidOrder(uint256 _orderId, uint256 _value) internal {
        uint256 beforeBalance = IERC20(orders[_orderId].quoteToken).balanceOf(address(this));
        require(IERC20(orders[_orderId].quoteToken).transferFrom(_msgSender(), address(this), _value), "OrderBid: transfer quote token failed");
        uint256 afterBalance = IERC20(orders[_orderId].quoteToken).balanceOf(address(this));
        require(afterBalance - beforeBalance == _value, "OrderBid: non-standard ERC20 token unsupported");

        if(orders[_orderId].lastBidder != address(0)) {
            require(IERC20(orders[_orderId].quoteToken).transfer(orders[_orderId].lastBidder, orders[_orderId].lastBid), "OrderBid: transfer refund failed");
        }

        orders[_orderId].lastBidder = _msgSender();
        orders[_orderId].lastBid = _value;
        orders[_orderId].bids += 1;
        orders[_orderId].updateTime = block.timestamp;
    }

    function _cancelOrder(uint256 _orderId) internal {
        IERC721(collection).safeTransferFrom(address(this), _msgSender(), orders[_orderId].tokenId);

        orders[_orderId].orderState = 3;
        orders[_orderId].updateTime = block.timestamp;
        if(openOrderToIndex[_orderId] != openOrders.length - 1) {
            uint256 index = openOrderToIndex[_orderId];
            openOrders[index] = openOrders[openOrders.length -1];
            openOrderToIndex[openOrders[index]] = index;
        }
        openOrderToIndex[_orderId] = 0;
        openOrders.pop();
    }

    function _settleOrder(uint256 _orderId) internal {
        require(IERC20(orders[_orderId].quoteToken).transfer(orders[_orderId].seller, orders[_orderId].lastBid), "OrderSettle: transfer tokens failed");
        IERC721(collection).safeTransferFrom(address(this), orders[_orderId].lastBidder, orders[_orderId].tokenId);

        orders[_orderId].orderState = 2;
        orders[_orderId].buyer = orders[_orderId].lastBidder;
        orders[_orderId].updateTime = block.timestamp;
        if(openOrderToIndex[_orderId] != openOrders.length -1 ) {
            uint256 index = openOrderToIndex[_orderId];
            openOrders[index] = openOrders[openOrders.length - 1];
            openOrderToIndex[openOrders[index]] = index;
        }
        openOrderToIndex[_orderId] = 0;
        openOrders.pop();
    }

    // ----- VIEWS ----- //
    function getOrderLength() external view returns (uint256) {
        return orders.length;
    }

    function getOpenOrderLength() external view returns (uint256) {
        return openOrders.length;
    }

    function getIncrement() external view returns (uint) {
        return increment;
    }

    function getCollectionAddress() external view returns (address) {
        return collection;
    }

    function getOrderById(uint256 _orderId) external view returns (OrderInfo memory) {
        return orders[_orderId];
    }

    // ----- RESTRICTION FUNCTIONS ----- //
    function setIncrement(uint _value) external onlyOwner {
        increment = _value;
    }
}

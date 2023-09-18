// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Address.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

/**
 * @dev Auction info data structure
 * @param orderId The identifier of the order, incrementing uint256 starting from 0
 * @param orderState The state of the order, 1 is open, 2 is filled, 3 is failed
 * @param tokenContract The contract address of token placed in the order
 * @param tokenId The token type placed in the order
 * @param tokenCount The token count placed in the order
 * @param price The minimum bidding price for order
 * @param endTime The end time of the auction
 * @param seller The address of the seller that created the order
 * @param buyers The address of the buyers of the order
 * @param bidCount The number of bids placed on the order
 * @param bidders The address of the bidders of the order
 * @param bids The bid prices of the order
 * @param lastBidder The address of the last bidder that bids on the order
 * @param lastBid The last bid price on the order(the highest bid price)
 * @param createTime The timestamp of the order creation
 * @param updateTime The timestamp of last order info update
 */
struct AuctionInfo {
    uint256 orderId;
    uint256 orderState;
    address tokenContract;
    uint256 tokenId;
    uint256 tokenCount;
    uint256 price;
    uint256 endTime;
    address seller;
    address[] buyers;
    uint256 bidCount;
    address[] bidders;
    uint256[] bids;
    address lastBidder;
    uint256 lastBid;
    uint256 createTime;
    uint256 updateTime;
}

contract Auction is Ownable {
    using Address for address;

    AuctionInfo[] internal orders;
    uint256[] internal openOrders;
    mapping(uint256 => uint256) internal openOrderToIndex;
    mapping(uint256 => uint256) internal orderBalances;

    uint256 public gasPricePerToken = 10 ** 16; // 0.01 ETH per token for gas fee reserves

    /**
     * @dev MUST emit when a new auction is created in Market.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order created.
     * The `_tokenContract` argument MUST be the contract address of the token placed on auction.
     * The `_tokenId` argument MUST be the token type placed on auction.
     * The `_tokenCount` argument MUST be the token count of `_tokenId`
     * The `_minPrice` argument MUST be the minimum starting price for the auction bids.
     * The `_endTime` argument MUST be the time for ending the auction.
     */
    event OrderAuction(address _seller, uint256 indexed _orderId, address _tokenContract, uint256 indexed _tokenId, uint256 _tokenCount, uint256 _minPrice, uint256 _endTime);

    /**
     * @dev MUST emit when a bid is placed on an auction order.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_bidder` argument MUST be the address of the bidder who made the bid.
     * The `_orderId` argument MUST be the id of the order been bid on.
     * The `_price` argument MUST be the price of the bid.
     */
    event OrderBid(address indexed _seller, address indexed _bidder, uint256 indexed _orderId, uint256 _price);

    /**
     * @dev MUST emit when an order is filled.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order fulfilled.
     * The `_price` argument MUST be the price of the fulfilled order.
     */
    event OrderFilled(address _seller, uint256 indexed _orderId, uint256 _price);

    /**
     * @dev MUST emit when an order is failed.
     * @dev Only an open auction order can be failed
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order failed.
     */
    event OrderFailed(address indexed _seller, uint256 indexed _orderId);

    /**
     * @dev MUST emit when ERC1155 token is transferred to this contract
     */
    event ERC1155TokenReceived(address indexed _operator, address indexed _from, uint256 _id, uint256 _value, bytes _data);

    /**
     * @notice Create a new order for auction
     * @param _tokenContract The contract address of token placed on auction
     * @param _tokenId The token placed on auction
     * @param _tokenCount The count of token placed on auction
     * @param _minPrice The minimum starting price for bidding on the auction
     * @param _endTime The time for ending the auction
     */
    function createOrderForAuction(address _tokenContract, uint256 _tokenId, uint256 _tokenCount, uint256 _minPrice, uint256 _endTime) external payable {
        require(IERC1155(_tokenContract).isApprovedForAll(_msgSender(), address(this)), "AuctionOrder: Auction is not approved by seller");
        require(_tokenContract.isContract(), "AuctionOrder: invalid contract address");
        require(_minPrice > 0, "AuctionOrder: price cannot be zero");
        require(IERC1155(_tokenContract).balanceOf(_msgSender(), _tokenId) >= _tokenCount, "AuctionOrder: insufficient tokens");
        require(_endTime > block.timestamp, "AuctionOrder: end time is expired");
        require(msg.value >= gasPricePerToken * _tokenCount, "AuctionOrder: insufficient ETH for gas fee reserve");
        
        uint256 orderId = _createOrder(_tokenContract, _tokenId, _tokenCount, _minPrice, _endTime);
        (bool success, ) = payable(address(this)).call{ value: msg.value }("");
        require(success, "AuctionOrder: failed to send ETH");
        orderBalances[orderId] += msg.value;
        
        emit OrderAuction(_msgSender(), orderId, _tokenContract, _tokenId, _tokenCount, _minPrice, _endTime);
    }

    /**
     * @notice Bid on an auction order
     * @dev The value of the bid must be greater than or equal to the minimum starting price of the order
     * @dev If the order has past bid(s), the value of the bid must be greater than the last bid
     * @param _orderId The id of the auction order
     */
    function bidForOrder(uint256 _orderId) external payable {
        require(orders[_orderId].orderState == 1, "AuctionBid: this auction is not open");
        require(orders[_orderId].endTime > block.timestamp, "AuctionBid: end time is expired");
        require(msg.value >= orders[_orderId].price && msg.value > orders[_orderId].lastBid, "AuctionBid: invalid bid");

        _bidOrder(_orderId, msg.value);

        emit OrderBid(orders[_orderId].seller, _msgSender(), _orderId, msg.value);
    }

    /**
     * @notice Settle an auction
     * @dev Only an auction order past its end time can be settled
     * @dev Only seller can settle an auction
     * @param _orderId The id of the order to be settled
     */
    function settleOrder(uint256 _orderId) external payable {
        require(_msgSender() == orders[_orderId].seller, "AuctionSettle: caller is not the seller");
        require(orders[_orderId].endTime < block.timestamp, "AuctionSettle: auction is not expired");
        require(orders[_orderId].bidders.length == orders[_orderId].bids.length, "AuctionSettle: bidders and bids length does not match");

        if(orders[_orderId].bidCount >= orders[_orderId].tokenCount) {
            uint256 bidCount = orders[_orderId].bids.length;
            uint256 finalPrice = orders[_orderId].bids[bidCount - orders[_orderId].tokenCount];
            for(uint256 i = 0; i < bidCount; i++) {
                if(orders[_orderId].bids[i] < finalPrice) {
                    uint256 refundAmount = orders[_orderId].bids[i] + gasPricePerToken;
                    payable(orders[_orderId].bidders[i]).transfer(refundAmount);
                    orderBalances[_orderId] -= refundAmount;
                } else {
                    uint256 refundAmount = orders[_orderId].bids[i] - finalPrice;
                    payable(orders[_orderId].bidders[i]).transfer(refundAmount);
                    orderBalances[_orderId] -= refundAmount;
                    // Transfer tokens to winners
                    IERC1155(orders[_orderId].tokenContract).safeTransferFrom(address(this), orders[_orderId].bidders[i], orders[_orderId].tokenId, 1, "");
                    orders[_orderId].buyers.push(orders[_orderId].bidders[i]);
                }
            }
            
            orders[_orderId].orderState = 2;
            orders[_orderId].updateTime = block.timestamp;
            if(openOrderToIndex[_orderId] != openOrders.length - 1) {
                uint256 index = openOrderToIndex[_orderId];
                openOrders[index] = openOrders[openOrders.length - 1];
                openOrderToIndex[openOrders[index]] = index;
            }
            openOrderToIndex[_orderId] = 0;
            openOrders.pop();

            emit OrderFilled(orders[_orderId].seller, _orderId, finalPrice);
        } else {
            for(uint256 i = 0; i < orders[_orderId].bidders.length; i++) {
                uint256 refundAmount = orders[_orderId].bids[i] + gasPricePerToken;
                payable(orders[_orderId].bidders[i]).transfer(refundAmount);
                orderBalances[_orderId] -= refundAmount;
            }
            // Transfer tokens back to seller
            IERC1155(orders[_orderId].tokenContract).safeTransferFrom(address(this), orders[_orderId].seller, orders[_orderId].tokenId, orders[_orderId].tokenCount, "");

            orders[_orderId].orderState = 3;
            orders[_orderId].updateTime = block.timestamp;
            if(openOrderToIndex[_orderId] != openOrders.length - 1) {
                uint256 index = openOrderToIndex[_orderId];
                openOrders[index] = openOrders[openOrders.length - 1];
                openOrderToIndex[openOrders[index]] = index;
            }
            openOrderToIndex[_orderId] = 0;
            openOrders.pop();

            emit OrderFailed(orders[_orderId].seller, _orderId);
        }

        // Withdraw remaining ETH to seller
        if(orderBalances[_orderId] > 0) {
            payable(orders[_orderId].seller).transfer(orderBalances[_orderId]);
            delete orderBalances[_orderId];
        }
    }

    /**
     * @notice internal createOrder utility method
     */
    function _createOrder(address _tokenContract, uint256 _tokenId, uint256 _tokenCount, uint256 _price, uint256 _endTime) internal returns (uint256) {
        IERC1155(_tokenContract).safeTransferFrom(_msgSender(), address(this), _tokenId, _tokenCount, "");

        AuctionInfo memory newOrder;
        newOrder.orderId = orders.length;
        newOrder.orderState = 1;
        newOrder.tokenContract = _tokenContract;
        newOrder.tokenId = _tokenId;
        newOrder.tokenCount = _tokenCount;
        newOrder.price = _price;
        newOrder.endTime = _endTime;
        newOrder.seller = _msgSender();
        newOrder.createTime = block.timestamp;
        newOrder.updateTime = block.timestamp;
        orders.push(newOrder);

        openOrderToIndex[newOrder.orderId] = openOrders.length;
        openOrders.push(newOrder.orderId);

        return newOrder.orderId;
    }

    /**
     * @notice internal bidOrder utility method
     */
    function _bidOrder(uint256 _orderId, uint256 _value) internal {
        (bool success, ) = payable(address(this)).call{ value: _value }("");
        require(success, "BidOrder: failed to send ETH");
        orderBalances[_orderId] += _value;
        
        orders[_orderId].lastBidder = _msgSender();
        orders[_orderId].lastBid = _value;
        orders[_orderId].bidders.push(_msgSender());
        orders[_orderId].bids.push(_value);
        orders[_orderId].bidCount += 1;
        orders[_orderId].updateTime = block.timestamp;
    }

    /**
     * @dev Withdraw ETH from contract
     * @dev Only owner can withdraw ETH in emergency situation
     */
    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
     * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes memory _data) public returns (bytes4) {
        emit ERC1155TokenReceived(_operator, _from, _id, _value, _data);
        return this.onERC1155Received.selector;
    }
}

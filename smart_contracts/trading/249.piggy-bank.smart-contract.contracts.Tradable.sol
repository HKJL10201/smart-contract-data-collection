//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Tradable {

    struct SellOrder {
        uint256 id;
        address seller;
        uint256 amount;
        uint256 price;
        bool active;
    }

    SellOrder[] internal orders;

    event OrderPlaced(uint256 indexed id, address indexed seller, uint256 amount, uint256 price);
    event Selled(uint256 indexed id, address indexed seller, address indexed buyer, uint256 amount, uint256 price);
    event UpdatedOrderPrice(uint256 indexed id, uint256 newPrice);
    event UpdatedOrderAmount(uint256 indexed id, uint256 newAmount);

    constructor() {}

    function _placeOrder(uint256 amount, uint256 price) internal {
        require(amount > 0, "Tradable: you can only place a sell order of a positive non null amount");
        require(price > 0, "Trabable: you order token price must be postive and not null");
        
        uint256 orderId = orders.length;

        orders.push(SellOrder(orderId, msg.sender, amount, price, true));
        emit OrderPlaced(orderId, msg.sender, amount, price);
    }

    function _removeOrder(uint256 orderId) internal {
        require(orders[orderId].seller == msg.sender, "Tradable: that order is not yours");
        require(orders[orderId].active == true, "Tradable: order was already removed or buyed");

        orders[orderId].active = false;
    }

    function _updateOrderPrice(uint256 orderId, uint256 newPrice) internal {
        require(orders[orderId].seller == msg.sender, "Tradable: that order is not yours");
        require(orders[orderId].active == true, "Tradable: order was already removed or buyed");
        require(newPrice > 0, "Trabable: you order token price must be postive and not null");

        orders[orderId].price = newPrice;

        emit UpdatedOrderPrice(orderId, newPrice);
    }

    function _buyOrder(uint256 orderId, uint256 amount) internal {
        require(orders[orderId].seller != msg.sender, "Tradable: you cannot buy your own order");
        require(orders[orderId].active == true, "Tradable: order was already removed or buyed");
        require(amount <= orders[orderId].amount, "Tradable: cannot buy amount greater than placed on order.");

        orders[orderId].amount -= amount;

        if (orders[orderId].amount == 0) orders[orderId].active = false;
        else emit UpdatedOrderAmount(orderId, orders[orderId].amount);
        
        emit Selled(orderId, orders[orderId].seller, msg.sender, amount, orders[orderId].price);
    }

    function _getOrder(uint256 orderId) internal view returns (SellOrder memory) {
        return orders[orderId];
    }

    function _listOrders() internal view returns (SellOrder[] memory) {
        return orders;
    }
}
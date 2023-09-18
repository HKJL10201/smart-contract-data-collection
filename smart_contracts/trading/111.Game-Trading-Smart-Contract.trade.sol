// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract GameTradeSystem {
    struct Item {
        uint id;
        string name;
        address owner;
        bool listed;
        uint price;
    }

    mapping(uint => Item) public items;
    uint public itemCount;

    event ItemAdded(uint indexed itemId, string itemName, address indexed owner);
    event ItemListed(uint indexed itemId, uint price);
    event ItemUnlisted(uint indexed itemId);
    event ItemSold(uint indexed itemId, address indexed previousOwner, address indexed newOwner, uint price);

    constructor() {
        itemCount = 0;
    }

    function addItem(string memory _name) public {
        itemCount++;
        items[itemCount] = Item(itemCount, _name, msg.sender, false, 0);
        emit ItemAdded(itemCount, _name, msg.sender);
    }

    function listForSale(uint _itemId, uint _price) public {
        require(items[_itemId].id != 0, "Invalid item");
        require(items[_itemId].owner == msg.sender, "You don't own this item");
        require(!items[_itemId].listed, "Item is already listed");

        items[_itemId].listed = true;
        items[_itemId].price = _price;

        emit ItemListed(_itemId, _price);
    }

    function unlistForSale(uint _itemId) public {
        require(items[_itemId].id != 0, "Invalid item");
        require(items[_itemId].owner == msg.sender, "You don't own this item");
        require(items[_itemId].listed, "Item is not listed");

        items[_itemId].listed = false;
        items[_itemId].price = 0;

        emit ItemUnlisted(_itemId);
    }

    function buyItem(uint _itemId) public payable {
        require(items[_itemId].id != 0, "Invalid item");
        require(items[_itemId].listed, "Item is not listed");
        require(items[_itemId].owner != msg.sender, "You cannot buy your own item");
        require(msg.value >= items[_itemId].price, "Insufficient payment");

        address payable previousOwner = payable(items[_itemId].owner);
        address payable newOwner = payable(msg.sender);

        items[_itemId].owner = newOwner;
        items[_itemId].listed = false;
        items[_itemId].price = 0;

        uint paymentExcess = msg.value - items[_itemId].price;

        previousOwner.transfer(items[_itemId].price);
        if (paymentExcess > 0) {
            newOwner.transfer(paymentExcess);
        }

        emit ItemSold(_itemId, previousOwner, newOwner, items[_itemId].price);
    }
}

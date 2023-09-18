pragma solidity ^0.6.4;

import "./Item.sol";
import "./Ownable.sol";


//We want to initially deploy the ItemManager contract
contract ItemManager is Ownable {

    //enum of the state the item is in
    enum SupplyChainState{Created, Paid, Delivered}

    //Creating the item structure
    struct S_Item {
        // from contract "Item"
        Item _item;

        string _identifier;
        uint _itemPrice;
        //Simplifying enum to _state
        ItemManager.SupplyChainState _state;
    }

    //Mapping stores each item as an object/struct 
    mapping(uint => S_Item) public items;

    uint itemIndex;

    event SupplyChainStep(uint _itemIndex, uint _step, address _itemAddress);

    //This creates the item. Param 1 is name of item, param 2 is its price
    //Only the owner can create items
    function createItem(string memory _identifier, uint _itemPrice) public onlyOwner{
        //creates new instance of Item
        Item item = new Item(this, _itemPrice, itemIndex);
        items[itemIndex]._item = item;
        
        //Assigns item's attributes to the mapping
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = SupplyChainState.Created;
        //returns index of item and step in the enum
        emit SupplyChainStep(itemIndex, uint(items[itemIndex]._state), address(item));
        itemIndex++;
    }

    function triggerPayment(uint _itemIndex) public payable {
        //The address must send a full payment and the item must be in the "Created" state
        require(items[_itemIndex]._itemPrice == msg.value, "Sorry! We only accept full payments...");
        require(items[_itemIndex]._state == SupplyChainState.Created, "Seems like you have already paid for your product!");
        items[_itemIndex]._state = SupplyChainState.Paid;

        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));

    }

    function triggerDelivery(uint _itemIndex) public onlyOwner {
        //Item must be in the "Paid" state
        require(items[_itemIndex]._state == SupplyChainState.Paid, "Seems like the product has been delivered or hasn't been created!");
        items[_itemIndex]._state = SupplyChainState.Delivered;

        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }
}
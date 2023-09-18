// SPDX-License-Identifier: MIT-Modern-Variant

pragma solidity >0.7.0 <0.9.0;

contract Marketplace {
    address public seller;
    address public buyer;
    mapping (address => uint) public balances;

    event ListItem(address seller, uint price);
    event PurchasedItem(address seller, address buyer, uint price);

    enum StateType {
          ItemAvailable,
          ItemPurchased
    }

    StateType public State;

    constructor() {
        seller = msg.sender;
        State = StateType.ItemAvailable;
    }

    function initial_balance(address partecipant, uint amount) public {
        require(msg.sender == partecipant, "You can update just your own balance");
        balances[partecipant] = amount;
    }

    function buy(address seller, address buyer, uint price) public payable {
        require(price <= balances[buyer], "Insufficient balance");
        State = StateType.ItemPurchased;
        balances[buyer] -= price;
        balances[seller] += price;

        emit PurchasedItem(seller, buyer, msg.value);
    }
}

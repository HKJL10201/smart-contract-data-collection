
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract HotelRoom {
    //you will learn
    //how to pay smart contracts
    //modifiers
    //events

    //create an emun with 2 status so we can keep track of our hotel room
    enum Statuses { Vacant, Occupied }
    Statuses currentStatus;

    //create an event for others that want to subscribe to events like a smart lock to unlock the door
    event Occupy(address _occupant, uint _value);


    //state variable is written to the block chain.  Address to pay owner is the creator of the contract
    address payable public owner;

    // constructor is called once when the contract is created.  person who deployed this contract to the block chain is the owner
    constructor() {
        owner = msg.sender;
        currentStatus = Statuses.Vacant;
    }

    //solidity has a concept of requirements that you can set.  example don't allow someone to book the hotel room if it not vacant or prevent them from paying twice
    modifier onlyWhileVacant{
         //check status.  Require checks to see if it is true then continue if not it is false it will halt and displays error message
        require(currentStatus == Statuses.Vacant, "Currently Occupied");
        _;
    }
    // this modifier allows you to pass in an amount
    modifier costs (uint _amount) {
        //check price.  If the message value is >= to 2 ether then true and continue
        require(msg.value >= _amount, "Not enought Ether provided");
        _;
    }
    //when the room is booked and the payment is sent to the contract the payment is sent to the owner of the contract
    //emit sends an event to the owner that the room is Occupied
    //using the receive feature makes the below items to occur
    receive() external payable onlyWhileVacant costs(2 ether) {
        currentStatus = Statuses.Occupied;
        owner.transfer(msg.value);
        emit Occupy(msg.sender, msg.value);
    }
}
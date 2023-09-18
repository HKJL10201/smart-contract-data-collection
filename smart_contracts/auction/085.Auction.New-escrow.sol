// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract Escrow {
    uint public bid;
    uint public payment;
    address public  thirdParty;
    uint public auctionEndTime;

    mapping(address => uint) public biddings;

    modifier onlyThirdParty() {
        require(msg.sender == thirdParty);
        _;
    }

    constructor() public {
        thirdParty = msg.sender;
    }

    function bidding(address bidder, uint amount) public onlyThirdParty payable {
        amount = msg.value;
        bid =  biddings[bidder];

        if(msg.value < bid) revert("Bid is not high enough!");
        if(block.timestamp > auctionEndTime) revert("The auction has ended!");
        
        bid -= amount;     
    }

    function sell(address payable bidder, uint amount) public onlyThirdParty payable {
        amount = msg.value;
        payment = biddings[bidder] + amount;
    }

    function withdraw(address payable bidder) onlyThirdParty public payable returns(bool) {
        payment = biddings[msg.sender];
        if(payment > 0) {
            biddings[msg.sender] = payment;
        }
        return true;
    }

    function auctionEnd() public view  {

        if(block.timestamp < auctionEndTime) revert("The auction has not yet ended.");
    }



}
//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.6.0 <0.9.0;
 
contract Auction{

    address public owner;
    mapping(uint => address) itemAuctioneers;

    constructor() public{
        owner = msg.sender;
    }
    
    function pushItem(address auctioneer, uint itemHash) public {
        require(msg.sender == owner, "You are not allowed");
        itemAuctioneers[itemHash] = auctioneer;
    }

    function completeAuction(uint itemHash) public view returns(bool){
        //only auctioneer of this item can finish its item's auction
        require(itemAuctioneers[itemHash] == msg.sender, "It is not your item");
        return true;        
    }

    function payForItem(uint itemHash) public payable{
        payable(itemAuctioneers[itemHash]).transfer(msg.value);
    }

}
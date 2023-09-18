// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract OnlineAuction{
    mapping(address => uint)BiddersData;
    uint highestBid;
    address highestBidder;


    // input bid
    function addBid()public payable{
        // value cannot be zero
        require(msg.value>0, "Your bid cammot be zero");
        
        // store input
        uint CalculateTotalBid = BiddersData[msg.sender] + msg.value;


        
        // check for highest bid
        
        require(CalculateTotalBid>highestBid, "Value lower than highest bid");
        highestBid=CalculateTotalBid;

        BiddersData[msg.sender]=highestBid;
        highestBidder=msg.sender;
    }

    // check bidders bid
    function checkBid(address _address)internal view returns(uint){
        return BiddersData[_address];
    }

    // get highest bid 
    function getHighestBidAmount() public view returns(uint){
        return highestBid;
    }

    // get highest bidder
    function getHighestBidder()public view returns(address){
        return highestBidder;
    }





}
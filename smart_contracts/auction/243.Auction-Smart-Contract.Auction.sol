// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract auction{
    address payable public auctioneer;
    uint start_time_block; //Time is  counted in terms of block. 1 block is created in every 15 seconds
    uint end_time_block;
    
    enum AuctionState{Started,Running,Ended,Cancelled} //TO verify Auction States
    AuctionState auctionstate;
    
    
    uint public highest_payable_bid;
    uint bid_increment;

    

    address payable public highest_bidder;

    mapping (address => uint) public bids;

    constructor(){
     auctioneer = payable(msg.sender);
     start_time_block = block.number;
     end_time_block = block.number + 240;  //Max time of Auction is set to 1 hour
     auctionstate = AuctionState.Running;
     bid_increment = 1 ether;
    }

    modifier notAuctionner(){
        require(auctioneer != msg.sender,"Auctioneer is not Allowed to bid");
        _;
    }
    modifier isAuctionner(){
        require(auctioneer == msg.sender,"Auctioneer is not Allowed to bid");
        _;
    }
    modifier started(){
        require(block.number > start_time_block,"Bid has not yet started");
        _;
    }
    modifier ending(){
    require(block.number < end_time_block,"Bid has already Ended");
    _;
    }
    function min(uint a, uint b) pure private returns(uint){
        if(a>b)
            return b;
        else
            return a;
    }
    function cancelled() public isAuctionner{
        auctionstate = AuctionState.Cancelled;
    }
    function ended() public isAuctionner{
        auctionstate = AuctionState.Ended;
    }  
    function bid() payable public notAuctionner started ending{
        require(auctionstate == AuctionState.Running );//Only bid works when auction state is Running
        require(msg.value >= 1 ether,"Minimum Amount of bid is 1 Ether"); //setting minimum amount of Bid

        uint currentbid = bids[msg.sender] + msg.value;   

        require(currentbid>highest_payable_bid);
        bids[msg.sender] = currentbid;

        if(currentbid < bids[highest_bidder]){
            highest_payable_bid = min(currentbid+bid_increment,bids[highest_bidder]);
        }
        else{
            highest_payable_bid = min(currentbid,bids[highest_bidder]+bid_increment);
            highest_bidder = payable(msg.sender);
        }
    }
    function finilizaAuction() public{  //run by bidders to get their amount back
        require(auctionstate == AuctionState.Cancelled || auctionstate == AuctionState.Ended||block.number > end_time_block);
        require(msg.sender == auctioneer || bids[msg.sender] > 0);
        address payable recipient;
        uint value;
        if(auctionstate == AuctionState.Cancelled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];

        }
        else{
            if(msg.sender == auctioneer){
                recipient = auctioneer;
                value = highest_payable_bid;
            }
            else if(msg.sender == highest_bidder){
                recipient = highest_bidder;
                value = bids[highest_bidder]-highest_payable_bid;
            }
            else{
                recipient = payable(msg.sender);
                value = bids[msg.sender];
            }
        }
        recipient.transfer(value);
        bids[msg.sender] = 0;
    }
    function auctioneerBalance()public isAuctionner{ //to give the goods amount to auctioneer 
        auctioneer.transfer(highest_payable_bid);
    }

}
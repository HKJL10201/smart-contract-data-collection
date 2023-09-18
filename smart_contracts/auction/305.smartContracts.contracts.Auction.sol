// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract AuctionCreator {

    Auction[] public auctions;

    function createAuction() public {
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}
contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    
    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;

    mapping (address => uint) public bids;

    uint bidIncrement;

    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 3;
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
    }

    modifier notOwner() {
        require(msg.sender != owner, "Owner cannot place bids");
        _;
    }

    modifier afterStart(){
        require (block.number >= startBlock, "The auction has not started yet");
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock, "The auction is finished");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this method");
        _;
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running, "The auction is ont in the Running state");
        require(msg.value >= 100, "The amount bid should be greater than 100 wei");

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "amount should be greater than highestBindingBid");

        bids[msg.sender] = currentBid;
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min (currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }


    function cancelAuction() public view onlyOwner {
        auctionState == State.Cancelled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Cancelled || block.number > endBlock, "The auction is still ongoing, and was not cancelled");
        require(msg.sender == owner || bids[msg.sender] > 0, "Only the owner or a bidder can finalize the auction");

        address payable recipient;
        uint value;

        if(auctionState == State.Cancelled){ // auction cancelled, bidder getting their money back
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else { // auctionb ended (not cancelled)
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            } else { // this is a bidder
                if(msg.sender == highestBidder){ // highestbider
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else { // neigther the owner nor the highest bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        // resseting the bids of the recipient to 0
        bids[recipient] = 0;
        recipient.transfer(value);


    }

    function min(uint a, uint b) pure internal returns (uint){
        if(a <= b){
            return a;
        }else {
            return b;
        }
    }
}
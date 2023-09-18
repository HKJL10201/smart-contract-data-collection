// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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
    string public ipfshash;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;
    
    mapping(address => uint) public bids;
    
    uint bidIncreament;
    
    constructor(address payable creator) {
        owner = creator;
        auctionState = State.Running;
        
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfshash = "";
        bidIncreament = 10;
    }
    
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }
    
    modifier afterStart() {
        require(block.number > startBlock);
        _;
    }
    
    modifier beforeEnd() {
        require(block.number < endBlock);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function min(uint a, uint b) internal pure returns(uint) {
        if(a <= b) {
            return a;
        }else {
            return b;
        }
    }
    
    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }
    
    function placeBid() public payable notOwner afterStart beforeEnd returns(bool){
        require(auctionState == State.Running);
        require(msg.value >= 0.001 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        
        bids[msg.sender] = currentBid;
        
        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncreament, bids[highestBidder]);
        }else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncreament);
            highestBidder = msg.sender;
        }
        
        return true;
    }
    
    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address payable recipient;
        uint value;
        
        if(auctionState == State.Canceled) {
            recipient = msg.sender;
            value = bids[msg.sender];
        }else {
            if(msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            }else {
                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else {
                    recipient = msg.sender;
                    value = bids[msg.sender];
                }
            }
        }
        recipient.transfer(value);
    }
    
}

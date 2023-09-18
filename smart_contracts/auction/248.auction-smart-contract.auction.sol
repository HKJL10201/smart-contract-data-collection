// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

contract auction{
    address payable public auctioner;
    uint public stblock;//start block
    uint public etblock;//end time


    //states of auction
    enum auction_state{start, running, end, cancel}
    auction_state public auctionState;

    uint public highestPayableBid;
    uint public bidIncrement;

    address payable public highestBidder;
    mapping(address=>uint) public bids;

    //initializing values
    constructor(){
        auctioner = payable(msg.sender);
        auctionState = auction_state.running;
        stblock = block.number;
        etblock = stblock + 240;
        bidIncrement = 1 ether;
    }

    //added modifiers
    modifier notOwner(){
        require(msg.sender != auctioner, "Owner cannot bid");
        _;
    }
    modifier owner(){
        require(msg.sender == auctioner, "You are not the owner");
        _;
    }
    modifier started(){
        require(block.number >= stblock);
        _;
    }
    modifier ended(){
        require(block.number < etblock);
        _;
    }

    function min(uint a, uint b) private pure returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }

    function cancelAuc() public owner{
        auctionState = auction_state.cancel;
    }

    function bid() public payable notOwner started ended{
        require(auctionState == auction_state.running, "Auction is ended");
        require(msg.value >= 1 ether, "Ether is less than 1");

        uint currentBidder = bids[msg.sender] + msg.value;

        require(currentBidder > highestPayableBid, "Less than highestpayable");

        bids[msg.sender] = currentBidder;
        if(currentBidder > bids[highestBidder]){
            highestPayableBid = min(currentBidder, bids[highestBidder]+bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function endAuc() public owner{
        auctionState = auction_state.end;
    }
    
    function finalizeAuction() public {
        require(auctionState == auction_state.cancel || auctionState == auction_state.end || block.number > etblock);
        require(msg.sender == auctioner || bids[msg.sender] > 0);

        address payable person;
        uint value;
        if(auctionState == auction_state.cancel){
            //if a bidder wants to cancel he/she can do that. then his/her money will be transferred to his/her account
            person = payable(msg.sender);
            value = bids[msg.sender];
        }else{
            if(msg.sender == auctioner){
                person = auctioner;
                value = highestPayableBid; 
            }else{
                if(msg.sender == highestBidder){
                    person = highestBidder;
                    value = bids[highestBidder] - highestPayableBid;
                }else{
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(value);
    }
} 
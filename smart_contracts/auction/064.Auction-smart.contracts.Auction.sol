// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}

    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor () {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320; //( 7days in seconds / 15)
        ipfsHash = "";
        bidIncrement= 100;
    }

    modifier notOwner(){
        require(msg.sender !=owner);
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) {
        return (a<=b) ? a : b; 
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    } 

    function placeBid() public payable notOwner afterStart beforeEnd{
        require (auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid= bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid+bidIncrement, bids[highestBidder]);
        }else {
            highestBindingBid = min(currentBid, bids[highestBidder]+ bidIncrement);
            highestBidder = payable(msg.sender);
        }
        
    }
    
    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] >0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) { //auction was cancelled
            recipient = payable(msg.sender);
            value = bids[msg.sender];            
        } else { //auction ended but not cancelled
            if(msg.sender == owner) { // if this is owner
                recipient =owner;
                value = highestBindingBid;
            } else { 
                if(msg.sender == highestBidder) { //this is highest bidder
                    recipient= highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else { //Neither owner not highest bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        recipient.transfer(value);
    }
}   
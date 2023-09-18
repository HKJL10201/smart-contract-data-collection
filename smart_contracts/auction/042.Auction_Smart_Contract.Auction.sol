// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Auction {
    address payable public owner; // owner of this smart contract.
    uint public startTime; // Start time of auction;
    uint public endTime; // End time of auction;

    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;

    uint public highestPayableBid; // highest payable bid ( selling price )
    uint public bidInc; // incrementing bid

    address payable public highestBidder; // the person who have bidded highest amount.

    mapping(address => uint) public bidders; // all bidders with their address and value.


    //  Constructor
    constructor(){
        owner = payable(msg.sender);

        auctionState = State.Running;

        startTime = block.number;
        endTime = startTime + 240;

        bidInc = 1 ether;
    }


    // modifier for not owner;
    modifier onlyOwner {
        require(msg.sender == owner, "Sorry you are not permitted to use it.");
        _;
    }
    modifier notOwner {
        require(msg.sender != owner, "Owner Can't bid");
        _;
    }

    // modifier for the auction is started.
    modifier started {
        require(block.number > startTime);
        _;
    }

    // modifier for the auction is ended.
    modifier isEnded {
        require(block.number <= endTime);
        _;    
    }


    // to cancel the auction
    function cancelAuction() public onlyOwner {
        auctionState = State.Cancelled;
    }

    // 
    function min(uint first, uint second) pure private returns(uint){
        if(first <= second){
            return first;
        }else{
            return second;
        }
    }

    // function to bid in auction
    function placeBid() payable public notOwner started isEnded {
        require(auctionState == State.Running);
        require(msg.value >= 1 ether);

        // current bid
        uint currentBid = bidders[msg.sender] + msg.value;

        // The current bid should be always greater then highest person's bid.
        require(currentBid > highestPayableBid);

        bidders[msg.sender] = currentBid;

        if(currentBid < bidders[highestBidder]){
            highestPayableBid = min(currentBid+bidInc, bidders[highestBidder]);
        }else {
            highestPayableBid = min(currentBid, bidders[highestBidder] +bidInc);
            highestBidder = payable(msg.sender);
        }

    }

    
    // auction winner decision.
    function finalize() public {
        require(auctionState == State.Cancelled || block.number >= endTime);
        require(msg.sender == owner || bidders[msg.sender] > 0);
        
        address payable person;
        uint value;

        if(auctionState == State.Cancelled) {
            person = payable(msg.sender);
            value = bidders[msg.sender];

        }else{
            if(msg.sender == owner){
                person = owner;
                value = highestPayableBid; 
            }else{
                if(msg.sender == highestBidder){
                    person = highestBidder;
                    value = bidders[highestBidder] - highestPayableBid;
                }else{
                    person = payable(msg.sender);
                    value = bidders[msg.sender];
                }
            }
        }

        bidders[msg.sender] = 0;
        person.transfer(value);

    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SmartAuction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {
        Started,
        Running,
        Ended,
        Cancelled
    }
    State public auctionState;

    uint public highestBindingBid;
    address payable highestBidder;

    mapping(address => uint) public bids; 

    uint bidIncrement;

    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid; 

        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);

            highestBidder = payable(msg.sender);
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState =  State.Cancelled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Cancelled || block.number > endBlock);

        //Only a bidder or the owner can finalize the auction
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if (auctionState == State.Cancelled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else { // Auction not cancelled
            if (msg.sender == owner) { // this is the owner
                recipient = owner;
                value = highestBindingBid;
            } else { // this is a bidder
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else { // this is neither the owner not the highest idder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        bids[recipient] = 0; // This way a bidder cannot request their funds more than once
        recipient.transfer(value);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Auction {
    /* Type decleration */
    enum AuctionState {
        Started,
        Running,
        Ended,
        Cancelled
    }
    AuctionState public auctionState;

    /* State Variables */
    address payable public auctioneer;
    uint256 public startBlock; //start time
    uint256 public endBlock; //end time

    /* Auction Variables */
    uint256 public highestBid;
    uint256 public highestPayableBid;
    uint256 public bidIncrement;
    address payable public highestBidder;
    mapping(address => uint256) public bids;

    constructor() {
        auctioneer = payable(msg.sender);
        startBlock = block.number;
        endBlock = startBlock * 5760;
        bidIncrement = 1 ether;
        auctionState = AuctionState.Running;
    }

    /*Modifiers*/
    modifier notOwner() {
        require(
            msg.sender != auctioneer,
            "Owner cannot bid and only owner can execute auction"
        );
        _;
    }

    modifier owner() {
        require(
            msg.sender == auctioneer,
            "Owner cannot bid and only owner has access of this"
        );
        _;
    }

    modifier started() {
        require(block.number > startBlock);
        _;
    }

    modifier ended() {
        require(block.number < endBlock);
        _;
    }

    /*Helper function*/
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a <= b) return a;
        else return b;
    }

    /*Auction Function*/

    function cancelAuction() public owner {
        auctionState = AuctionState.Cancelled;
    }

    function bid() public payable owner {
        require(auctionState == AuctionState.Running);
        require(msg.value >= 1 ether);

        uint256 currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestPayableBid);

        bids[msg.sender] = currentBid;

        if (currentBid > bids[highestBidder]) {
            highestPayableBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        } else {
            highestPayableBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public {
        require(
            auctionState == AuctionState.Cancelled || block.number > endBlock
        );
        require(msg.sender == auctioneer || bids[msg.sender] > 0);

        address payable person;
        uint256 value;

        if (auctionState == AuctionState.Cancelled) {
            person = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if (msg.sender == auctioneer) {
                person = auctioneer;
                value = highestPayableBid;
            } else {
                if (msg.sender == highestBidder) {
                    person = highestBidder;
                    value = bids[highestBidder] - highestPayableBid;
                } else {
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        bids[msg.sender] = value;
        person.transfer(value);
    }
}

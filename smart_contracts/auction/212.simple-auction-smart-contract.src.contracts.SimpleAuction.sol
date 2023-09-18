// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SimpleAuction {

    address payable public owner;
    string public itemName;
    address public highestBidder;
    uint public highestBid;
    bool public started;

    mapping(address => uint) pendingReturns;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(string itemName, address winner, uint amount);
    event AuctionStarted(address owner, string item, uint currentBid);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();


    constructor() {}

    function startAuction(string memory item, address payable addr) external {
        if (started) {
            revert AuctionNotYetEnded();
        }

        owner = addr;
        itemName = item;

        started = true;
        emit AuctionStarted(owner, item, highestBid);
    }

    function bid() external payable {
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;


            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {
        // if (!started)
            // revert AuctionEndAlreadyCalled();

        emit AuctionEnded(itemName, highestBidder, highestBid);
        owner.transfer(highestBid);

        started = false;
        itemName = '';
        highestBidder = address(0);
        highestBid = 0;
    }
}
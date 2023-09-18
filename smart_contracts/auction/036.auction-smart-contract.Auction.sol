// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

/// @title Decentralized Auction
/// @author Arian Hosseini | https://github.com/aryanhosseini
/// @notice It is a simple Auction smart contract
contract Auction {
    // State variables
    address payable public auctioneer;
    address public highestBidder;

    uint public highestBid; // ether
    uint public bidCounter;

    uint public auctionStartTime;
    uint public auctionEndTime;
    bool endStatus;

    struct Bids {
        address payable Bidder;
        uint OfferedAmount;
    }

    mapping(uint => Bids) public listOfBids;

    // Events 
    event Bid(uint bidId, uint offeredAmount, address bidder, uint time);
    event AuctionEnded(uint auctionStartTime, uint auctionEndTime, uint currentTime, uint highestBid, address winner);
    event WithdrawBid(uint offeredAmount, address bidder, uint time, uint previousBid, address previousBidder);


    // Modifiers
    modifier onlyAuctioneer {
        require(msg.sender == auctioneer, "You aren't the auctioneer!");
        _;
    }

    modifier closeAfter(uint _time) {
        require(block.timestamp <= _time, "The Auction has ended! Try later!");
        _;
    }

    constructor(uint _biddingTime) {
        auctioneer = payable(msg.sender);

        highestBid = 0 ether;
        endStatus = false;
        bidCounter = 0;
        
        auctionStartTime = block.timestamp;
        auctionEndTime = auctionStartTime + _biddingTime;
    }

    // Custom Errors
    error InsufficientBalance(uint bidderBalance, uint offeredAmount, string reason);
    error BeyondYourBid(uint highestBid, uint offeredAmount, string reason);

    // Bids
    function bid() public payable closeAfter(auctionEndTime) {
        uint offeredAmount = msg.value;

        // Checks if offered amount is less than or equal to the balance of the bidder
        if (msg.sender.balance < offeredAmount) {
            revert InsufficientBalance({
                bidderBalance: msg.sender.balance,
                offeredAmount: offeredAmount,
                reason: "Your offered amount is greater than your balance!"
            });
        } 

        if (offeredAmount <= highestBid && msg.sender != highestBidder) {
            revert BeyondYourBid({
                highestBid: highestBid,
                offeredAmount: offeredAmount, 
                reason: "Sorry, Unfortuantely, There is an offered amount greater than or equal to your offered bid! You can check the highest bid."
            });

        } 
        
        highestBidder = msg.sender;
        highestBid = offeredAmount;

        bidCounter++;
        listOfBids[bidCounter] = Bids(payable(highestBidder), highestBid);

        emit Bid(bidCounter, highestBid, highestBidder, block.timestamp);

        // Checks if the highest bid is greater than the offered amount of the previous bidder, then refunds the amount of the previous bidder
        if (highestBid > listOfBids[bidCounter - 1].OfferedAmount) {
            listOfBids[bidCounter - 1].Bidder.transfer(listOfBids[bidCounter - 1].OfferedAmount);
        }

    }

    // Refunds the offered amount of the last bidder
    function withdraw() public {
        require(msg.sender == listOfBids[bidCounter].Bidder, "You received your bid amount already or was not the bidder!");
        payable(listOfBids[bidCounter].Bidder).transfer(listOfBids[bidCounter].OfferedAmount);

        emit WithdrawBid(listOfBids[bidCounter].OfferedAmount, listOfBids[bidCounter].Bidder, block.timestamp, listOfBids[bidCounter - 1].OfferedAmount, 
        listOfBids[bidCounter - 1].Bidder);

        delete listOfBids[bidCounter];
        delete highestBidder;
        delete highestBid;
        bidCounter--;
    }

    // Closes the auction after a specific time
    function finish() public onlyAuctioneer {
        require(block.timestamp >= auctionEndTime, "The Auction hasn't ended yet!");
        
        endStatus = true;
        auctioneer.transfer(highestBid);

        emit AuctionEnded(auctionStartTime, auctionEndTime, block.timestamp, highestBid, highestBidder);
    }
}
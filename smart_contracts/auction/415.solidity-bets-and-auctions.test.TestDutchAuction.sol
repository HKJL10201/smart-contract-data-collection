// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestFramework.sol";


contract TestDutchAuction {

    DutchAuction testAuction;
    MockTimer timer;

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 1000000000 wei;

    // Allow contract to receive money.
    receive() external payable {}
    
    fallback() external payable {}

    constructor() {}

    function setupContracts() public {
        timer = new MockTimer(0);
        testAuction = new DutchAuction(
            address(this),  // Seller
            address(0),     // Judge -> No judge anybody can call finalize.
            timer, // Timer
            300,   // Initial price
            10,    // Bidding period
            20     // Offer price decrement
        );
    }

    event LogEvent(bool value, string msg);
    event BalanceEvent(uint balance);

    function makeBid(
        uint bidValue,
        uint bidTime,
        uint expectedPrice,
        bool expectedResult,
        string memory message
    ) internal {
        DutchAuctionBidder bidder = new DutchAuctionBidder(testAuction);
        payable(address(bidder)).transfer(bidValue); // Give bidder money to bid
        timer.setTime(bidTime); // Set up time
        address previousHighestBidder = testAuction.getHighestBidder();
        uint initialAuctionBalance = address(testAuction).balance;
        bool result = bidder.bid(bidValue); // Expected result
        if (expectedResult == false) {
            Assert.isFalse(result, message);
            Assert.equal(previousHighestBidder, testAuction.getHighestBidder(), "No highest bidder should be declared after invalid bid");
        } else {
            emit LogEvent(result, "Result should be true");
            Assert.isTrue(result, message);
            Assert.equal(address(testAuction).balance, initialAuctionBalance + expectedPrice, "Auction should retain final price");
            Assert.equal(address(bidder).balance, bidValue - expectedPrice, "Bidder should be refunded excess bid amount");
            Assert.equal(address(bidder), testAuction.getHighestBidder(), "Bidder should be declared the highest bidder");
        }
    }

    function testCreateDutchAuction() public {
        setupContracts();
    }

    function testLowBids() public {
        setupContracts();
        makeBid(299, 0, 0, false, "Low bid should be rejected");
        makeBid(240, 2, 0, false, "Low bid should be rejected");
        makeBid(100, 5, 0, false, "Low bid should be rejected");
    }

    function testExactBid() public {
        setupContracts();
        makeBid(300, 0, 300, true, "Exact bid should be accepted");
        setupContracts();
        makeBid(280, 1, 280, true, "Exact bid should be accepted");
        setupContracts();
        makeBid(120, 9, 120, true, "Exact bid should be accepted");
    }

    function testValidBidAfterInvalid() public {
        setupContracts();
        makeBid(299, 0, 0, false, "Low bid should be rejected");
        makeBid(300, 0, 300, true, "Valid bid after failed bid should succeed");
    }

    function testLateBid() public {
        setupContracts();
        makeBid(300, 11, 0, false, "Late bid should be rejected");
    }

    function testSecondValidBid() public {
        setupContracts();
        makeBid(280, 1, 280, true, "Exact bid should be accepted");
        makeBid(300, 0, 0, false, "Second bid should be rejected");
    }

    function testRefundHighBid() public {
        setupContracts();
        makeBid(300, 2, 260, true, "High bid should be accepted");
    }

    function testFinishingAuctionSuccessful() public {
        setupContracts();
        makeBid(280, 1, 280, true, "Exact bid should be accepted");
        Assert.isTrue(testAuction.getAuctionOutcome() == Auction.Outcome.SUCCESSFUL, "Auction should be finished successfully");
    }

    function testFinishingAuctionNotSuccessful() public {
        setupContracts();
        makeBid(300, 11, 0, false, "Late bid should be rejected");
        timer.setTime(12);
        testAuction.enableRefunds();
        Assert.isTrue(testAuction.getAuctionOutcome() == Auction.Outcome.NOT_SUCCESSFUL, "Auction should not be finished successfully");
    }

}
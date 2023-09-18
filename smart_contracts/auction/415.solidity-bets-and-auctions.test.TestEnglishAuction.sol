// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestFramework.sol";


contract TestEnglishAuction {

    EnglishAuction testAuction;
    EngAuctionBidder alice;
    EngAuctionBidder bob;
    EngAuctionBidder carol;

    MockTimer t;

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 1000000000 wei;

    // Allow contract to receive money.
    receive() external payable {}

    fallback() external payable {}

    constructor() {}

    function setupContracts() public {
        t = new MockTimer(0);
        testAuction = new EnglishAuction(
            address(this), // Seller
            address(0),    // Judge -> no judge is necessary
            t,    // Timer
            300,  // Initial price
            10,   // Bidding period
            20    // Minimum Price increase
        );
        alice = new EngAuctionBidder(testAuction);
        bob = new EngAuctionBidder(testAuction);
        carol = new EngAuctionBidder(testAuction);
    }

    function makeBid(
        EngAuctionBidder bidder,
        uint bidValue,
        uint bidTime,
        bool expectedResult,
        string memory message
    ) internal {
        uint oldTime = t.getTime();
        t.setTime(bidTime);
        payable(address(bidder)).transfer(bidValue);
        bool result = bidder.bid(bidValue);

        if (expectedResult == false) {
            Assert.isFalse(result, message);
        } else {
            Assert.isTrue(result, message);
            Assert.equal(address(testAuction).balance, bidValue, "auction should retain bid amount");
        }
        t.setTime(oldTime);
    }

    function testCreateEnglishAuction() public {
        setupContracts();
        //do nothing, just verify that the constructor actually ran
    }

    function testLowInitialBids() public {
        setupContracts();
        makeBid(alice, 0, 0, false, "low bid should be rejected");
        makeBid(alice, 299, 9, false, "low bid should be rejected");
    }


    function testSingleValidBid() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        t.setTime(10);
        Assert.equal(testAuction.getHighestBidder(), address(alice), "single bidder should be declared the winner");
    }

    function testEarlyHighestBidder() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        t.setTime(9);
        Assert.equal(testAuction.getHighestBidder(), address(0), "no bidder should be declared before deadline");
    }

    function testLowFollowupBids() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        makeBid(bob, 319, 9, false, "low bid should be rejected");
        makeBid(bob, 250, 7, false, "low bid should be rejected");
    }

    function testRefundAfterOutbid() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        makeBid(bob, 320, 8, true, "valid bid should be accepted");
        Assert.equal(address(bob).balance, 0, "bidder should not retain funds");
        Assert.equal(address(testAuction).balance, 320, "auction should retain bidder's funds in escrow");
        Assert.equal(address(alice).balance, 300, "outbid bidder should receive refund");
    }

    function testLateBids() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        makeBid(bob, 320, 10, false, "late bid should be rejected");
        makeBid(carol, 500, 12, false, "late bid should be rejected");
    }

    function testIncreaseBid() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        makeBid(alice, 350, 5, true, "second valid bid should be accepted");
        t.setTime(14);
        Assert.equal(testAuction.getHighestBidder(), address(0), "no bidder should be declared before deadline");
        t.setTime(15);
        Assert.equal(testAuction.getHighestBidder(), address(alice), "repeat bidder should be declared the winner");
        Assert.equal(address(alice).balance, 300, "bidder should not retain funds");
        Assert.equal(address(testAuction).balance, 350, "auction should retain bidder's funds in escrow");
    }

    function testExtendedBidding() public {
        setupContracts();
        makeBid(alice, 300, 0, true, "valid bid should be accepted");
        makeBid(bob, 310, 4, false, "invalid bid should be rejected");
        makeBid(carol, 400, 8, true, "valid bid should be accepted");
        makeBid(bob, 450, 12, true, "valid bid should be accepted");
        makeBid(alice, 650, 15, true, "valid bid should be accepted");
        makeBid(bob, 660, 16, false, "invalid bid should be rejected");
        makeBid(alice, 750, 20, true, "valid bid should be accepted");
        makeBid(carol, 1337, 29, true, "valid bid should be accepted");
        t.setTime(38);
        Assert.equal(testAuction.getHighestBidder(), address(0), "no bidder should be declared before deadline");
        t.setTime(39);
        Assert.equal(testAuction.getHighestBidder(), address(carol), "final bidder should be declared the winner");
        Assert.equal(address(carol).balance, 400, "bidders should get valid refunds");
        Assert.equal(address(bob).balance, 1420, "bidders should get valid refunds");
        Assert.equal(address(alice).balance, 1700, "bidders should get valid refunds");
        Assert.equal(address(testAuction).balance, 1337, "auction should retain bidder's funds in escrow");
    }

    function testFinishingAuctionNotSuccessful() public {
        setupContracts();
        makeBid(alice, 299, 9, false, "low bid should be rejected");
        t.setTime(14);
        testAuction.enableRefunds();
        Assert.isTrue(testAuction.getAuctionOutcome() == Auction.Outcome.NOT_SUCCESSFUL, "Auction should not be finished successfully");
    }


}
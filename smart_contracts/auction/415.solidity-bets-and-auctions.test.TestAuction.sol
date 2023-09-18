// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestFramework.sol";


contract TestAuction {

    SimpleAuction testAuction;

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 1000000000 wei;
    Participant judge;
    Participant seller;
    Participant highestBidder;
    Participant other;

    // Allow contract to receive money.
    receive() external payable {}
    
    fallback() external payable {}

    constructor() {}

    function setupContracts(bool hasJudge) public {
        judge = new Participant();
        highestBidder = new Participant();
        seller = new Participant();
        other = new Participant();
        Timer timer = new MockTimer(0);
        testAuction = hasJudge
                    ? new SimpleAuction(address(seller), address(judge), timer)
                    : new SimpleAuction(address(seller), address(0), timer);

        payable(address(testAuction)).transfer(100 wei);

        judge.setAuction(testAuction);
        seller.setAuction(testAuction);
        highestBidder.setAuction(testAuction);
        other.setAuction(testAuction);
    }

    function testCreateContracts() public {
        setupContracts({hasJudge: true});
        Assert.isFalse(false, "this test should not fail");
        Assert.isTrue(true, "this test should never fail");
        Assert.equal(uint(7), uint(7), "this test should never fail");
    }

    // Tests method calls when in state NOT_FINISHED

    function testEarlyFinalize() public {
        setupContracts({hasJudge: true});
        Assert.isFalse(judge.callFinalize(), "Finalize with no declared highest bidder should be rejected");
    }

    function testEarlyRefund() public {
        setupContracts({hasJudge: true});
        Assert.isFalse(judge.callRefund(), "Refund with no declared highest bidder should be rejected");
    }

    function testUnauthorizedRefund() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(highestBidder));
        Assert.isFalse(highestBidder.callRefund(), "Unauthorized refund call should be rejected");
        Assert.isFalse(other.callRefund(), "Unauthorized refund call should be rejected");
    }

    function testUnauthorizedFinalize() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.SUCCESSFUL, address(highestBidder));
        Assert.isFalse(seller.callFinalize(), "Unauthorized finalize call should be rejected");
        Assert.isFalse(other.callFinalize(), "Unauthorized finalize call should be rejected");
    }

    function testJudgeFinalize() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.SUCCESSFUL, address(highestBidder));
        Assert.isTrue(judge.callFinalize(), "Judge finalize call should succeed");
        Assert.equal(address(seller).balance, 100, "seller should receive funds after finalize");
    }

    function testHighestBidderFinalize() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.SUCCESSFUL, address(highestBidder));
        Assert.isTrue(highestBidder.callFinalize(), "Highest bidder finalize call should succeed");
        Assert.equal(address(seller).balance, 100, "seller should receive funds after finalize");
    }

    function testPublicFinalize() public {
        setupContracts({hasJudge: false});
        testAuction.finish(Auction.Outcome.SUCCESSFUL, address(highestBidder));
        Assert.isTrue(other.callFinalize(), "Public finalize call should succeed");
        Assert.equal(address(seller).balance, 100, "seller should receive funds after finalize");
    }

    function testJudgeRefund() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(highestBidder));
        Assert.isTrue(judge.callRefund(), "Judge refund call should succeed");
        Assert.equal(address(highestBidder).balance, 100, "Highest bidder should receive funds after refund");
    }

    function testSellerRefund() public {
        setupContracts({hasJudge: false});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(highestBidder));
        Assert.isTrue(seller.callRefund(), "Seller refund call should succeed");
        Assert.equal(address(highestBidder).balance, 100, "Highest bidder should receive funds after refund");
    }

    function testFinalizeWhenNoBidsPlaced() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(0));
        Assert.isFalse(judge.callFinalize(), "Judge finalize call should not succeed");
    }

    function testRefundWhenNoBidsPlaced() public {
        setupContracts({hasJudge: true});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(0));
        Assert.isFalse(judge.callRefund(), "Judge refund call should not succeed");

        setupContracts({hasJudge: false});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(0));
        Assert.isFalse(seller.callRefund(), "Judge refund call should not succeed");

        setupContracts({hasJudge: false});
        testAuction.finish(Auction.Outcome.NOT_SUCCESSFUL, address(0));
        Assert.isFalse(other.callRefund(), "Any refund call should not succeed");
    }

}
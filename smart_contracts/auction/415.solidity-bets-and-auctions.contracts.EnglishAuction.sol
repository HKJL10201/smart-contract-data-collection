// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auction.sol";

contract EnglishAuction is Auction {

    uint internal highestBid;
    uint internal initialPrice;
    uint internal biddingPeriod;
    uint internal lastBidTimestamp;
    uint internal minimumPriceIncrement;

    address internal highestBidder;

    constructor(
        address _sellerAddress,
        address _judgeAddress,
        Timer _timer,
        uint _initialPrice,
        uint _biddingPeriod,
        uint _minimumPriceIncrement
    ) Auction(_sellerAddress, _judgeAddress, _timer) {
        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;

        // Start the auction at contract creation.
        lastBidTimestamp = time();
    }

    function bid() public payable {
        require(msg.value >= (highestBid + minimumPriceIncrement) && msg.value >= initialPrice);
        require(time() < lastBidTimestamp + biddingPeriod);

        if (highestBidderAddress != address(0)) {
            payable(highestBidderAddress).transfer(highestBid);
        }

        highestBid = msg.value;
        highestBidderAddress = msg.sender;
        lastBidTimestamp = time();
    }

    function getHighestBidder() override public returns (address) {
        return (highestBidderAddress == address(0) || time() < lastBidTimestamp + biddingPeriod) ? address(0) : highestBidderAddress;
    }

    function enableRefunds() public {
        outcome = Outcome.NOT_SUCCESSFUL;
    }

}
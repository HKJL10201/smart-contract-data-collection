// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import "./Auction.sol";

contract AuctionFactory {
    //uint256 private constant OPEN_INTERVAL_THRESHOLD = 24 * 3600;
    uint256 private constant OPEN_INTERVAL_THRESHOLD = 0;
    uint256 private constant MAXIMUM_INTERVAL = 7 * 24 * 3600;
    uint256 private constant MAXIMUM_NUMBER_OF_BIDDERS_MIN_VALUE = 5;

    event AuctionDeployed(
        address contractAddress,
        address sellerAddress
    );

    function deployAuction(
        uint256 minimumBid,
        uint256 maximumNumberOfBidders,
        uint256 auctioneerCollateralAmount,
        uint256 interval,
        string memory infoCID
    ) public payable {
        if (interval < OPEN_INTERVAL_THRESHOLD) {
            revert Auction__IntervalBelowThreshold(interval, OPEN_INTERVAL_THRESHOLD);
        }

        if (interval > MAXIMUM_INTERVAL) {
            revert Auction__IntervalAboveMaximum(interval, MAXIMUM_INTERVAL);
        }

        if (msg.value < auctioneerCollateralAmount) {
            revert Auction__DidntCoverCollateral(msg.value, auctioneerCollateralAmount);
        }

        if (maximumNumberOfBidders < MAXIMUM_NUMBER_OF_BIDDERS_MIN_VALUE) {
            revert Auction__MaximumNumberOfBiddersTooLow(maximumNumberOfBidders, MAXIMUM_NUMBER_OF_BIDDERS_MIN_VALUE);
        }

        Auction auction = new Auction{value: msg.value}(
            minimumBid,
            maximumNumberOfBidders,
            auctioneerCollateralAmount,
            interval,
            msg.sender,
            infoCID
        );
        
        emit AuctionDeployed(address(auction), msg.sender);
    }
}
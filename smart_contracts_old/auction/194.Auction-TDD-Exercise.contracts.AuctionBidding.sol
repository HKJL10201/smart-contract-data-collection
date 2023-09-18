//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
    
contract AuctionBidding {
    
    struct AuctionDetails {
        bool inProgress;
        uint startingBid;
        uint minBidIncrement;
        uint currentBid;
        uint salePrice;
        uint auctionId;
        string itemName;
        address currentBidder;
        address winningBidder;
        address originalOwner;
    }

    struct AuctionUserInputs {
        uint startingBid;
        uint minBidIncrement;
        string itemName;
        address originalOwner;
    }

    AuctionDetails public currentAuction;
    
    mapping(uint => AuctionDetails) public closedAuctions;

    uint private nextAuctionId;

    event AuctionStarted(AuctionDetails);    
    event AuctionEnded(AuctionDetails);
    event NewBidMade(AuctionDetails);

    function startNewAuction(AuctionUserInputs memory auctionUserInputs) public {

        // TODO - Build an "AuctionDetails" object from the "AuctionUserInputs" provided by the user

        // TODO - set the auction details object as the "currentAuction"

        // TODO - At some point within this function, increment "nextAuctionId" and set it as the id for the current AuctionDetails object

        // TODO - emit the "AuctionStarted" event

    }

    function submitBid(uint bidAmount, uint auctionIndex) public {

        // TODO - check that the auctionIndex that the user is trying to bid on is currently "inProgress". Revert if not

        // TODO - check that the bid amount is greater than or equal to the current bid plus the "minBidIncrement". Revert if not

        // TODO - update "currentBid" and "currentBidder" values

        // TODO - emit the "NewBidMade" event

    }

    function endAuctionForCurrentItem() public {

        // TODO - modify auction details as needed (set "inProgress" to false, set "currentBidder" value as "winningBidder", and "salePrice" to the value of "currentBid" )

        // TODO - push the auction details object into our "closedAuctions" hash map, using the "auctionIndex" as the key

        // TODO - reset "currentAuction" to a cleared out object

        // TODO - emit the "AuctionEnded" event

    }

    function getFinishedAuctionDetails(uint auctionId) public returns (AuctionDetails memory) {

        // TODO - return the closed auction details object which has the auctionId passed in as an argument  

    }

}

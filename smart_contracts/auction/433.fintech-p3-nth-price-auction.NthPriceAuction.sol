// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./NthPriceAuctionToken.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/utils/math/SafeMath.sol";

contract NthPriceAuction{
    using SafeMath for uint;

    // Beneficiary of the auction.
    address payable public sellerAddress;
    // Time the auction ends.
    uint public auctionEndTime;
    // Number of items to auction and thus max number of winners.
    uint numItemsToAuction;
    // Set to true when auction ends.
    bool public auctionEnded;
    // Index for the smallest of the top N bids.
    uint smallestTopNBidsIndex;
    // Token for the item being auctioned.
    NthPriceAuctionToken token;
    // Address of the token.
    address public tokenAddress;

    // Bid structure used to store info about a bid that was placed.
    struct Bid {
        address bidder;
        uint value;
        uint timestamp;
    }

    // List of the top N bids.
    Bid[] topNBids;

    // Mapping to keep track of all bids that occurred.
    mapping(address => uint) bidsMapping;

    // Mapping to store bids that did not win, for the purpose of returning
    // to bidders after the auction ends.
    mapping(address => uint) bidsToReturn;

    // Modifier to ensure this action occurs within the timeframe of the auction.
    modifier withinAuction {
        require(block.timestamp <= auctionEndTime, "Bid is not within auction timeframe");
        _;
    }

    // Function to create an auction of `numItems` items,
    // for 'durationSeconds' seconds, on behalf of the
    // beneficiary address of `seller`.
    constructor (
        address payable seller,
        uint durationSeconds,
        uint numItems,
        string memory tokenURI
    ) {
        require(numItems > 0);

        sellerAddress = seller;
        uint startTime = block.timestamp;
        auctionEndTime = startTime.add(durationSeconds);
        numItemsToAuction = numItems;
        auctionEnded = false;
        smallestTopNBidsIndex = 0;
        
        //Create the NthPriceAuctionToken and save its address.
        token = new NthPriceAuctionToken(tokenURI);
        tokenAddress = address(token);
    }

    // Payable function that allows someone to send Ether to make a bid.
    function bid() public payable withinAuction returns (bool) {
        require(msg.value > 0, "Bid must be greater than 0");
        require(bidsMapping[msg.sender] == 0, "Sorry you can only bid once");
        require(msg.sender != sellerAddress, "Seller cannot bid in auction");

        // Save bid in bidsMapping.
        bidsMapping[msg.sender] = msg.value;

        // Save bid parameters in a struct object.
        Bid memory newBid = Bid(msg.sender, msg.value, block.timestamp);

        if (topNBids.length < numItemsToAuction) {
            // If there's any space in the list, add the new
            // bid to the list.
            topNBids.push(newBid);
        } else if (newBid.value > topNBids[smallestTopNBidsIndex].value) {
            // If the new bid is greater than the current smallest of
            // the top N bids, add the current smallest of the top N bids
            // address and bid value to the bidsToReturn mapping.
            bidsToReturn[topNBids[smallestTopNBidsIndex].bidder]
                = topNBids[smallestTopNBidsIndex].value;
        
            // Replace the current smallest bid with this new one.
            topNBids[smallestTopNBidsIndex] = newBid;
        } else {
            // If the bid does not make it into the top N list, put the
            // bidder's address and bid value into the bidsToReturn mapping
            // and return false.
            bidsToReturn[msg.sender] = msg.value;
            return false;
        }

        // Find the new smallest of the top N bids.
        uint minIndex = 0;
        for (uint i = 1; i < topNBids.length; i++) {
            // Using less than or equal here so that if there are duplicates
            // in the topNBids list, the newer one gets marked as the minIndex.
            // In this way, the newest duplicate is the one that will be replaced
            // by a higher bid.  As duplicate bids are outbid, the newest
            // duplicates are replaced before the older duplicates.  The older
            // duplicate bids are prioritized as winners.
            if (topNBids[i].value <= topNBids[minIndex].value) {
                minIndex = i;
            }
        }

        // Only after the loop is finished do we update the
        // storage variable.
        smallestTopNBidsIndex = minIndex;

        // If the bidder made it into the top N list, return true.
        return true;
    }

    function auctionEnd() public payable {
        require(!auctionEnded, "Auction can only be ended once");
        require(
            block.timestamp > auctionEndTime,
            "Auction cannot be ended during the auction time duration"
        );

        // Set bool so that auction can only be ended once.    
        auctionEnded = true;

        // Transfer Ether to the beneficiary, in the amount of
        // the smallest of the top N bids times the number of
        // bidders in the top N bids list.
        if (topNBids.length > 0) {
            uint amountToTransfer = topNBids[smallestTopNBidsIndex].value.mul(topNBids.length);
            sellerAddress.transfer(amountToTransfer);
        }

        // Add remainder between what each top N bidder bid, and
        // the price they paid (which was the smallest of the top N bids),
        // to the bidsToReturn mapping.
        for (uint i = 0; i < topNBids.length; i++) {
            uint remainderToReturn = topNBids[i].value.sub(topNBids[smallestTopNBidsIndex].value);
            bidsToReturn[topNBids[i].bidder] = remainderToReturn;

            //Award a token to each winner.
            token.mint(topNBids[i].bidder, 1);
        }
    }

    // Function for users that did not win to use to receive their bids
    // back. Due to security concerns, it is better to let the bidders
    // withdraw themselves rather then automatically send to them.
    function withdraw() public {
        require(bidsToReturn[msg.sender] > 0, "You don't have any funds to withdraw");

        // Send bid amount back to sender.
        if (false == payable(msg.sender).send(bidsToReturn[msg.sender])) {
            // If it fails, revert so they can try again later.
            revert("Transaction failed, please try again");
        } else {
            // Set to zero to prevent multiple withdraws.
            bidsToReturn[msg.sender] = 0;
        }
    }
}

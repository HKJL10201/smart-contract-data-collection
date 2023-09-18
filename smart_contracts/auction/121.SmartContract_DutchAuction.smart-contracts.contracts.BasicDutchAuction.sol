//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";

contract BasicDutchAuction{

    uint public reservePrice;
    uint public numBlocksAuctionOpen;
    uint public offerPriceDecrement;
    uint startingBlock;
    uint public auctionCloseBlock;
    address public sellerAccountAddr;
    address payable sellerAccount;
    bool public auctionEnd = false;
    address public buyer;

    constructor(uint _reservePrice, uint _numBlocksAuctionOpen, uint _offerPriceDecrement)
    {
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        startingBlock = block.number;
        auctionCloseBlock = startingBlock + numBlocksAuctionOpen;
        console.log(auctionCloseBlock);
        sellerAccountAddr = msg.sender;
        sellerAccount = payable(msg.sender);
    }

    function bid() public payable returns(bool)
    {
        require(auctionEnd == false && (block.number < auctionCloseBlock), "Bids are not being accepted, the auction has ended.");
        require(msg.value >= getCurrentBidPrice(), "Your bid price is less than the required auction price.");
        finalize();
        return true;
    }

    function getCurrentBidPrice() public view returns(uint)
    {
        console.log("Current block:  ",block.number);
        console.log("startingBlock block:  ",startingBlock);
        console.log("auctionCloseBlock block:  ",auctionCloseBlock);
        console.log("numBlocksAuctionOpen:  ",numBlocksAuctionOpen);
        console.log("reservePrice:  ",reservePrice);
        console.log("offerPriceDecrement:  ",offerPriceDecrement);
        require(block.number < auctionCloseBlock, "Auction is closed");
        uint currentMinPrice = reservePrice + (numBlocksAuctionOpen - ((block.number - startingBlock) * offerPriceDecrement));
        console.log(currentMinPrice);
        return currentMinPrice;
    }

    function finalize() internal
    {
        sellerAccount.transfer(msg.value);
        auctionEnd = true;
        buyer = msg.sender;
    } 
}
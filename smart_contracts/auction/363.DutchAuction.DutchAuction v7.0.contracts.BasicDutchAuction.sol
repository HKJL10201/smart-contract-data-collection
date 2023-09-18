// SPDX-License-Identifier: UNLICENSED

// npx hardhat compile
// npx hardhat test     REPORT_GAS=true - in front of npx if desired
// npx hardhat coverage

// This program creates a contract to manage the auction of a single, physical item at a single auction event

pragma solidity ^0.8.17;

contract BasicDutchAuction {
    uint256 public immutable reservePrice;
    uint256 public immutable numBlocksAuctionOpen;
    uint256 public immutable offerPriceDecrement;
    uint256 public immutable initialPrice;

    address public seller;
    address public winner;

    uint256 blockStart;
    uint256 totalBids = 0;
    bool public isAuctionOpen = true;

    constructor(
        uint256 _reservePrice, // minimum amount of wei that the seller is willing to accept for the item
        uint256 _numBlocksAuctionOpen, // number of blockchain blocks that the auction is open for
        uint256 _offerPriceDecrement // amount of wei that the auction price should decrease by during each subsequent block
    ) {
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        // sets the initial price to the equation below
        initialPrice =
            _reservePrice +
            _numBlocksAuctionOpen *
            _offerPriceDecrement;
        // assigning seller to the person who's currently connecting with the contract
        seller = msg.sender;
        // assigns the current block as the starting block
        blockStart = block.number;
    }

    // returns the current price of the item
    function getCurrentPrice() public view returns (uint256) {
        return initialPrice - (block.number - blockStart) * offerPriceDecrement;
    }

    // returns the reserve price
    function getReservePrice() public view returns (uint256) {
        return reservePrice;
    }

    // returns the number of blocks open auction is open for
    function getNumBlocksAuctionOpen() public view returns (uint256) {
        return numBlocksAuctionOpen;
    }

    // returns the price decrement
    function getPriceDecrement() public view returns (uint256) {
        return offerPriceDecrement;
    }

    // bid function makes checks, accepts or rejects bids, and executes the wei transfer if accepted
    function bid() public payable returns (address) {
        require(isAuctionOpen, "Auction is closed"); // checks to make sure the auction is still open
        require(
            winner == address(0),
            "You just missed out! There is already a winner for this item"
        ); // check if there is a winner
        require(msg.sender != seller, "Owner cannot submit bid on own item"); // check if the owner bids on own item
        require(
            block.number - blockStart <= numBlocksAuctionOpen,
            "Auction has closed - total number of blocks the auction is open for have passed"
        ); // check if the duration of the auction has passed by seeing what block we're on
        require(
            address(this).balance > 0,
            "Your accounts balance is not greater than 0"
        ); // checks if the bidding address's balance is greater than 0
        require(
            msg.value >= getCurrentPrice(),
            "You have not sent sufficient funds"
        ); // check if the buyer has bid a sufficient amount

        totalBids++; // increments totalBids by 1 every time a bid is entered

        require(totalBids > 0, "There must be at least one bid to finalize"); // checks if there is at least one bid on item

        winner = msg.sender; // assigns winner to address with first winning bid - finalize fn
        payable(seller).transfer(msg.value); // transfers wei from bidder to seller

        isAuctionOpen = false; // sets isAuctionOpen variable to false
        return winner;
    }

    // returns the address of the winning bid
    function getWinnerAddress() public view returns (address) {
        require(winner == msg.sender, "You are the winner"); // checks if the winner variable is the winning address
        return winner;
    }

    // returns the sellers address
    function getSellerAddress() public view returns (address) {
        return seller;
    }

    // returns balance of requested address
    function balanceOf(address) public view returns (uint256) {
        return address(this).balance;
    }
}

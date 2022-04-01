pragma solidity ^0.4.24;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract PennyAuctionContract is Ownable {
    uint256[] public bidIncrement;

    // uint256[] public auctionEnd;
    uint256[] public highBid;

    string[] public highBidder;

    // uint256 public timeIncrement = 10 minutes;

    constructor() public {}

    function addNewLot(
        uint256 _initialPrice,
        uint256 _bidIncrement
    ) public onlyOwner {
        highBidder.push("default"); // Set winner creator of the auction.
        bidIncrement.push(_bidIncrement);
        highBid.push(_initialPrice); // Add min price of the added product.
        // auctionEnd.push(now + timeIncrement); // Add time, where auction should finish.
    }

    event Bid(uint256 id, string uid, uint256 highBid);

    function bid(uint256 id, string uid) public onlyOwner {
        // require(now < auctionEnd[id], "Auction is finished.");
        require(keccak256(bytes(uid)) != keccak256(bytes(highBidder[id])), "Invalid uid. Already highBidder.");

        highBid[id] += bidIncrement[id];

        // auctionEnd[id] += timeIncrement;

        highBidder[id] = uid;

        emit Bid(id, highBidder[id], highBid[id]);
    }

    function getWinner(uint256 id) public view onlyOwner returns (string uid, uint256 bighBid) {
        // require(now > auctionEnd[id], "Auction is not finished.");

        return (highBidder[id], highBid[id]);
    }
}
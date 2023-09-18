// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Blind-Auction.sol";

contract BlindAuctionFactory {
    address[] public AllAuctions;
    address public Admin;

    constructor(){
        Admin = msg.sender;
    }

    function createBlindAuction(uint256 _AuctionDuration) public returns (address AuctionAddress){
        BlindAuction Auction = new BlindAuction(_AuctionDuration, Admin);
        AuctionAddress = address(Auction);
        AllAuctions.push(AuctionAddress);
    }
}

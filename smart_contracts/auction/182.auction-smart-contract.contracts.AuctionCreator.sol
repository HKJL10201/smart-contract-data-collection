// SPDX-License-Identifier: MIT 
pragma solidity >=0.5.0 <0.9.0;
import './Auction.sol';

contract AuctionCreator {
    address public owner;
    Auction[] deployed;

    constructor() {
        owner = msg.sender;
    }

    function deployAuction() public {
        Auction auction = new Auction(msg.sender);
        deployed.push(auction);
    }
}
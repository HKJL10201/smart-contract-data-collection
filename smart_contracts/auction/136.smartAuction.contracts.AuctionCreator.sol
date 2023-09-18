// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SmartAuction.sol";

contract AuctionCreator {
    SmartAuction[] public auctions;

    function createAuction() public {
        SmartAuction newAuction = new SmartAuction(msg.sender);

        auctions.push(newAuction);
    }
}
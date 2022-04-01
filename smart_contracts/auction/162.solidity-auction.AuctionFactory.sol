// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Auction.sol";

/**
 * @title AuctionFactory
 * @dev Allows creation and deployment of auctions
 */
contract AuctionFactory {
    Auction[] public deployedAuctions;

    /**
     * @dev Create a new Auction.
     */
    function deployAuction() public {
        Auction newAuction = new Auction(msg.sender);
        deployedAuctions.push(newAuction);
    }
}

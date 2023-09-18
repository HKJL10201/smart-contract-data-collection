pragma solidity ^0.4.24;

import "./Auction.sol";
import "./lib/ITub.sol";

contract AuctionProxy {
    function createAuction(
        address auction,
        address tub,
        bytes32 cdp,
        address token,
        uint256 ask,
        uint256 expiry,
        uint256 salt
    ) public {
        Auction(auction).listCDP(
            cdp,
            msg.sender,
            token,
            ask,
            expiry,
            salt
        );
        ITub(tub).give(cdp, auction);
    }
}
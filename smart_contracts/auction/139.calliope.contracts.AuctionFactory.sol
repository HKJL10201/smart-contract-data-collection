pragma solidity 0.8.7;

import "./Auction.sol";

error AuctionExists();

contract AuctionFactory is Ownable {
    bool auction;
    address auctionAddress;

    function createAuction(address _nft) external onlyOwner {
        if (auction) revert AuctionExists();
        Auction newAuction = new Auction(address(this));
        auctionAddress = address(newAuction);
        auction = true;
    }
}

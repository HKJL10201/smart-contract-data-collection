// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Auction.sol";

error AuctionExists();

contract SongNFT is ERC721URIStorage, Ownable {
    string public constant TOKEN_URI = "./nft.json";
    uint256 private amount;

    bool auction;
    address private auctionAddress;

    // address private constant mumbEth = 0x05f52c0475Fc30eE6A320973CA463BD6e4528549;
    // address private constant mumbUSDC = 0x3120f93ff440ec53c763a98ed6993fbf4118463f;

    constructor(
        uint256 _amount,
        string memory songName,
        string memory songSymbol
    ) ERC721(songName, songSymbol) {
        amount = _amount;
        _safeMint(msg.sender, _amount);
    }

    function createAuction(address _nft) external onlyOwner {
        if (auction) revert AuctionExists();
        Auction newAuction = new Auction(address(this));
        auctionAddress = address(newAuction);
        auction = true;
    }

    function tokenId(
        uint256 /*tokenId*/
    ) public view returns (string memory) {
        return TOKEN_URI;
    }

    function getAuctionAddress()
        external
        view
        returns (address _auctionAddress)
    {
        _auctionAddress = auctionAddress;
        return _auctionAddress;
    }
}

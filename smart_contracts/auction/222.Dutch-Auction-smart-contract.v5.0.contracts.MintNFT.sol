// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MintNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 totalNFTSupply;

    constructor(uint256 _totalNFTSupply) ERC721("NFTDutchAuctionTokens", "NDT") {
        totalNFTSupply = _totalNFTSupply;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= (totalNFTSupply-1), "All the NFTs are minted");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTMarketplace is ERC721, ERC721Holder {
    using SafeMath for uint256;

    struct NFTMetadata {
        string name;
        string description;
        string image;
        address creator;
    }

    mapping(uint256 => address) private nftOwners;
    mapping(uint256 => uint256) private nftPrices;
    mapping(uint256 => NFTMetadata) private nftMetadata;

    constructor() ERC721("NFT Marketplace", "NFTM") {}

    function createNFT(string memory name, string memory description, string memory image, uint256 price) public {
        uint256 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
        nftOwners[tokenId] = msg.sender;
        nftPrices[tokenId] = price;
        nftMetadata[tokenId] = NFTMetadata(name, description, image, msg.sender);
    }

    function buyNFT(uint256 tokenId) public payable {
        require(_exists(tokenId), "NFT doesn't exist");
        require(nftOwners[tokenId] != msg.sender, "You can't buy your own NFT");
        require(msg.value >= nftPrices[tokenId], "Insufficient funds");
        address seller = nftOwners[tokenId];
        nftOwners[tokenId] = msg.sender;
        nftPrices[tokenId] = nftPrices[tokenId];
    _transfer(seller, msg.sender, tokenId);
    payable(seller).transfer(msg.value);
}

function getNFTMetadata(uint256 tokenId) public view returns (string memory, string memory, string memory, address) {
    require(_exists(tokenId), "NFT doesn't exist");
    NFTMetadata memory metadata = nftMetadata[tokenId];
    return (metadata.name, metadata.description, metadata.image, metadata.creator);
}

function getNFTPrice(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "NFT doesn't exist");
    return nftPrices[tokenId];
}
}

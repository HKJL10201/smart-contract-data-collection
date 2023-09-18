//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract myNFTs is ERC721URIStorage, Ownable {
    struct DigitalArt {
        address artist;
        uint256 id;
        string name;
        string uri;
    }

    DigitalArt[] public arts;
    uint256 public artCount;

    mapping(address => bool) private ownerID; // .....

    event Mint(uint256 id, string name, string uri);
    
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        artCount = 0;
        ownerID[msg.sender] = true;
    }

    modifier onlyLiveToken(uint256 _nftId) {
        require(ownerOf(_nftId) != address(0), "Invalid NFT");
        _;
    }

    function getArtist(uint256 tokenId) external view returns(address){
        return arts[tokenId].artist;
    }

    function mint(string memory _name, string memory _uri, address artistAddress) external returns (uint256) {
        require(ownerID[msg.sender], "Only owner can access");
        DigitalArt memory nft;
        nft.id = artCount;
        nft.name = _name;
        nft.uri = _uri;
        nft.artist = artistAddress;
        arts.push(nft);
        artCount++;

        _mint(msg.sender, nft.id);
        _setTokenURI(nft.id, _uri);

        emit Mint(nft.id, nft.name, nft.uri);

        return nft.id;
    }

    function transfer(uint256 _nftId, address _target) external onlyLiveToken(_nftId) {
        require(_exists(_nftId), "Non existed NFT");
        // require(ownerOf(_nftId) == msg.sender, "Not approved");
        require(_target != address(0), "Invalid address");

        _transfer(ownerOf(_nftId), _target, _nftId);
    }
}
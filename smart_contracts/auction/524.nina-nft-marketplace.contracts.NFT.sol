//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    mapping(uint256 => string) _tokenUri;

    constructor(address marketPlaceAddress) ERC721("Monik Token", "MT") {
        contractAddress = marketPlaceAddress;
    }

    event TokenCreated(address indexed from, uint256 indexed itemId);

    function createToken(string memory tokenURI) public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenUri[newItemId] = tokenURI;
        setApprovalForAll(contractAddress, true);
        emit TokenCreated(msg.sender, newItemId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AbiodunAwoyemi is ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter private _myCounter;
    uint256 MAX_SUPPLY = 10;

    constructor() ERC721("AbiodunAwoyemi", "AA") {}

    function safeMint(address to, string memory uri) public{

        uint256 tokenId = _myCounter.current();
        require(tokenId <= MAX_SUPPLY, "Sorry, all NFTs have been minted!");
        _myCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
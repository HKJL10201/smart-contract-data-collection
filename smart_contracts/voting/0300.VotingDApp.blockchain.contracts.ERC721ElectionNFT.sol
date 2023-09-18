// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721ElectionNFT is ERC721 {
    using Counters for Counters.Counter;

    uint8 public constant decimals = 0;
    Counters.Counter private tokenId;
    
    constructor() ERC721("ERC721ElectionNFT", "ERC721ENFT") {}

    function mint(address owner) public {
        tokenId.increment();
        _mint(owner, tokenId.current());
    }
}
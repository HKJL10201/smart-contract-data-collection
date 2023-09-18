// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Example Contract implementing ERC721 for Tests
contract ERC721Token is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("ERC721Token", "721") {}

    function mint() external returns (uint256) {
        _tokenIds.increment();
        
        uint256 newNftTokenId = _tokenIds.current();
        super._mint(msg.sender, newNftTokenId);

        return newNftTokenId;
    }

    function id() public view returns (uint256) {
        return _tokenIds.current();
    }
}
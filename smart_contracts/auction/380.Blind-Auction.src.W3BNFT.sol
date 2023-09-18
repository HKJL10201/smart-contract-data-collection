// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract W3BNFT is ERC721{
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol){
    }

    function mint(uint256 _tokenId) public {
        _mint(msg.sender, _tokenId);
    }
}

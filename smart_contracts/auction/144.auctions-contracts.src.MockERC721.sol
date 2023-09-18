// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor(string memory _name, string memory _symbol, address receiver, uint256 id) ERC721(_name, _symbol) {
        _mint(receiver, id);
    }
}

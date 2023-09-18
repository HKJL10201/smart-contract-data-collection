// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

/// @title This is an example of an ERC721 implementation that can be used with the ERC721MarketPlace contract. 
///        It is placed here only for the purpose of testing our marketplace contract. In reality
///        the ERC721MarketPlace contract will support any ERC-721 compatible contract. 
contract MusicNFT is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {}
}

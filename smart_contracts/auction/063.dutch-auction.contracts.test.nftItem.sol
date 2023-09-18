// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title NFT item
 * @author Al-Qa'qa'
 * @notice This contract is for creating an NFT collection
 * @dev We minted one NFT item to use this contract address and this item in our DutchAuction testing
 */
contract NftItem is ERC721 {
  /**
   * Creating NFT collection address and mint one item to test it in our Auction
   *
   * @param _name NFT collection name
   * @param _symbol NFT collection symbol
   */
  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
    _safeMint(msg.sender, 0);
  }
}

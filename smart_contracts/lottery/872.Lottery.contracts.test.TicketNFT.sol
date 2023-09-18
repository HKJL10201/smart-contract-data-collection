// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract TicketNFT is ERC1155, ERC1155Supply, Ownable, ReentrancyGuard {
   using Strings for uint256;
   string public name;
   string public symbol;
   uint256 private currentIndex = 0;
   mapping(uint256 => string) private tokenURIs;

   constructor(
      string memory name_,
      string memory symbol_
   ) ERC1155("") {
      name = name_;
      symbol = symbol_;
   }

   function uri(uint256 _id) public view override returns (string memory) {
      require(exists(_id), "ERC1155Metadata: URI query for nonexistent token");

      return tokenURIs[_id];
   }

   function mintNFT(
      address owner_,
      uint256 tokenId_, 
      uint256 amount_
   ) external nonReentrant {
      _mint(owner_, tokenId_, amount_, bytes(""));
   }

   function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
   ) internal override(ERC1155, ERC1155Supply) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
   }
}
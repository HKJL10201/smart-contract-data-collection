// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// Import ERC1155 token contract from Openzeppelin
import "http://github.com/Openzeppelin/Openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "http://github.com/Openzeppelin/Openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract NthPriceAuctionToken is ERC1155, Ownable {
    // Items that are created with an assigned ID, AUCTIONED_ITEM has id 0.
    uint256 public constant AUCTIONED_ITEM = 0;
    
    constructor(string memory uri) ERC1155(uri) {}
    
    // Only owner can mint new tokens. A minted token is awarded to a specified account.
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, AUCTIONED_ITEM, amount, "");
    }
}
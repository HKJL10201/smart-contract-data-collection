// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "hardhat/console.sol";

contract AuctionToken is ERC20 {
    address contractAddress;

    constructor(address dutchAuctionAdd ,uint256 _totalSupply) ERC20("Auction Token", "ATC")  {
        contractAddress = dutchAuctionAdd;
        _mint(msg.sender, _totalSupply);
        approve(contractAddress, _totalSupply);
    }
    
}

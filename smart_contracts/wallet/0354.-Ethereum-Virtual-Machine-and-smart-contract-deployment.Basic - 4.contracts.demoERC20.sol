// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract demoERC20 is ERC20, Ownable {
  uint256 _decimals;
  address mintTo;

  constructor() ERC20("Kalyan", "GDSC") {
    _decimals = 10 ** 18;
    mintTo = msg.sender;
  }

  function mint(uint256 tokenAmount) public onlyOwner {
    _mint(mintTo, tokenAmount * _decimals);
  }

  function update_mintTo(address _mintTo) public onlyOwner {
    mintTo = _mintTo;
  }
}

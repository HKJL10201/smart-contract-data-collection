// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract AwesomeTokens is ERC20, Ownable {
  bool public tokenIsLocked;
  mapping(address => bool) public whitelisted;

  constructor(uint256 initialSupply) ERC20('AwesomeTokens', 'ATK') {
    _mint(msg.sender, initialSupply);
    whitelisted[msg.sender] = true;
    tokenIsLocked = true;
  }

  modifier tokenUnlock() {
    require(
      whitelisted[msg.sender] == true || tokenIsLocked == false,
      'Token is locked'
    );
    _;
  }

  function whitelist(address _address) external onlyOwner {
    whitelisted[_address] = true;
  }

  function removeWhitelist(address _address) external onlyOwner {
    whitelisted[_address] = false;
  }

  function unlockTokens() external onlyOwner {
    tokenIsLocked = false;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override tokenUnlock {}
}

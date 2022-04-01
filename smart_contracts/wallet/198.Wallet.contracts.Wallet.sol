// SPDX-License-Identifier: None
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * THIS CONTRACT HAS NOT BEEN AUDITED, USE AT YOUR OWN RISK
 *
 * @title Wallet
 *
 * @dev Contract that allows for storage of Ether and tokens that abide by
 * the ERC20 standard.
 *
 * Inherits from openzeppelin contract Ownable, allowing for onlyOwner modifier
 * to be used.  Owner set to caller on deployment.
 */

contract Wallet is Ownable {

  /**
   * @dev Initializes contract, sets deployer as owner.
   */
  constructor() Ownable() {}

  /**
   * @dev Allows contract to receive tokens from any ERC20 compliant contract.
   *
   * @param tokenAddress, an address of an ERC20 token contract
   * @param amount, amount to be transferred
   */
  function receiveERC20(address tokenAddress, uint amount)
    external
  {

    IERC20 token = IERC20(tokenAddress);
    require(token.balanceOf(msg.sender) >= amount, "Insufficient funds");
    token.transferFrom(msg.sender, address(this), amount);

  }

  /**
   * @dev Allows contract to send tokens from any ERC20 compliant contract
   *
   * @param tokenAddress, an address of an ERC20 token contract
   * @param recipient, address to receive ERC20 token
   * @param amount, amount to be transferred
   */
  function sendERC20(address tokenAddress, address recipient, uint amount)
    external
    onlyOwner
  {

    IERC20 token = IERC20(tokenAddress);
    require(token.balanceOf(msg.sender) >= amount, "Insufficient funds");
    token.transfer(recipient, amount);

  }

  /**
   * @dev Receives Ether sent to contract
   */
  receive() external payable {}

  /**
   * @dev Allows contract to send Ether to other addresses
   *
   * @param recipient, address that is to receive Ether
   * @param amount, uint amount of Ether to be sent
   */
  function sendEther(address payable recipient, uint amount)
    external
    onlyOwner
  {

    require(address(this).balance >= amount, "Insufficient funds");
    recipient.transfer(amount);

  }
}

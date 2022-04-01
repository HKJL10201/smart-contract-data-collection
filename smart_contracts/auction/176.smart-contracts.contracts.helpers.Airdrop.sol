//SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAirdrop.sol";


/**
 * @title ERC20 Airdrop dapp smart contract
 */
contract Airdrop is IAirdrop, Ownable {
  using SafeERC20 for IERC20;

  /**
   * @dev doAirdrop is the main method for distribution
   * @param token airdropped token address (PIECE address)
   * @param addresses address[] addresses to airdrop
   * @param amounts address[] values for each address
   */
  function doAirdrop(address token, address[] calldata addresses, uint256 [] calldata amounts) external override returns (uint256) {
    require(addresses.length > 0 && addresses.length == amounts.length, "doAirdrop: invalid input arrays!");

    uint256 i = 0;
    while (i < addresses.length) {
      if (addresses[i] != address(0)) {
        IERC20(token).safeTransferFrom(msg.sender, addresses[i], amounts[i]);
      }

      i += 1;
    }

    return i;
  }

  function emergencyExit(address payable receiver) external override onlyOwner {
    (bool success, ) = receiver.call{value: address(this).balance}("");
    require(success, "emergencyExit: Failed to transfer funds!");
  }

  function emergencyExit(address token, address receiver) external override onlyOwner {
    IERC20(token).safeTransfer(receiver, IERC20(token).balanceOf(address(this)));
  }
}
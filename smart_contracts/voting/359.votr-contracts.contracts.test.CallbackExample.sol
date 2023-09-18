// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../interfaces/ICallback.sol';

contract CallbackExample is ICallback {
  uint256 public winnerIndex;
  address public pollAddress;
  address public pollTypeAddress;

  function callback(
    uint256 _winningChoiceIndex,
    address _pollAddress,
    address _pollTypeAddress
  ) external override {
    winnerIndex = _winningChoiceIndex;
    pollAddress = _pollAddress;
    pollTypeAddress = _pollTypeAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICallback {
  function callback(
    uint256 winningChoiceIndex,
    address pollAddress,
    address pollTypeAddress
  ) external;
}

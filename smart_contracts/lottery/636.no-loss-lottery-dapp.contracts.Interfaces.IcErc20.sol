// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IcErc20 {
  function balanceOf(address) external view returns (uint);
  function mint(uint) external returns (uint);
  function balanceOfUnderlying(address) external returns (uint);
  function redeem(uint) external returns (uint);
}
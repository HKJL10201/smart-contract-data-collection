// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.4 <0.9.0;

interface ERC20Interface {
  function transfer(address _to, uint256 _value) external returns (bool success);
  function balanceOf(address _owner) external view returns (uint256 balance);
}
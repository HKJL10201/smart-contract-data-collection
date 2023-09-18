pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
    function totalSupply() external returns (uint256);
    function balanceOf(address who) external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.12;


/**
 * @title IAirdrop
 */
interface IAirdrop {
    function doAirdrop(address token, address[] calldata addresses, uint256 [] calldata amounts) external returns (uint256);
    function emergencyExit(address payable receiver) external;
    function emergencyExit(address token, address receiver) external;
}
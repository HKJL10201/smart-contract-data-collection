// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IAaveLendingPool {

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function getReservesList() external view returns (address[] memory);
}

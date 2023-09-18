// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20Base {
    function mint(address to, uint256 amount) external;

    function symbol() external;

    function burn(address owner, uint256 amount) external;
}

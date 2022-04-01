pragma solidity ^0.7.3;

//SPDX-License-Identifier: MIT

interface CEthInterface {
    function mint() external payable;

    function redeemUnderlying(uint256 redeemAmount)
        external
        view
        returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);
}

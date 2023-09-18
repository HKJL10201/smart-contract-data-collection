//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title SimplicyWalletDiamond interface
 */
interface ISimplicyWalletDiamond {
    function version() external view returns (string memory);
}

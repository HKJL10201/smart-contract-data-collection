// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IPriceCalculator {
    /**
    * @notice Returns the current price, in USD, of the given asset.
    * @dev Returns 0 if the asset is not supported.
    * @param asset The address of the asset.
    * @return uint The USD price of the given asset.
    */
    function getUSDPrice(address asset) external view returns (uint);
}
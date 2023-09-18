// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPriceCalculator {
    function getUSDPrice(address asset) external view returns (uint);
}
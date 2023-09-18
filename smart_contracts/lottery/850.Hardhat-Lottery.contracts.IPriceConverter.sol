// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IPriceConverter {
    function getConversionRate(uint256 ETHAmount) external view returns (uint256);
}

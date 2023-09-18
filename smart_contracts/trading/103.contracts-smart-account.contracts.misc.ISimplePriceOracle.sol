// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../external-protocols/compound/CErc20.sol";
import "../external-protocols/compound/CToken.sol";

interface ISimplePriceOracle {
    function setUnderlyingPrice(CToken cToken, uint256 underlyingPriceMantissa) external;

    function setDirectPrice(address asset, uint256 price) external;
}

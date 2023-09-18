// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IERC20Upgradeable } from "@openzeppelin/contracts/token/ERC20/IERC20Upgradeable.sol";

interface ICToken is IERC20Upgradeable {
    function exchangeRateCurrent() external returns (uint256);
}

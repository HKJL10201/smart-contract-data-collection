// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contractsV4/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { IERC165 } from "@solidstate/contracts/introspection/IERC165.sol";
import { IDiamondBase } from "@solidstate/contracts/proxy/diamond/base/IDiamondBase.sol";
import { IDiamondReadable } from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

/**
 * @title SimplicyDiamond interface
 */
interface ISimplicyDiamond is
    IDiamondBase,
    IDiamondReadable,
    IDiamondWritable,
    IERC165 
{
    /**
     * @notice get the address of the fallback contract
     * @return fallback address
     */
    function getFallbackAddress() external view returns (address);

    /**
     * @notice set the address of the fallback contract
     * @param fallbackAddress fallback address
     */
    function setFallbackAddress(address fallbackAddress) external;
}

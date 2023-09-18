// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IUbeswapPathManager {
    /**
    * @dev Returns the path from 'fromAsset' to 'toAsset'
    * @notice The path is found manually before being stored in this contract
    * @param fromAsset Token to swap from
    * @param toAsset Token to swap to
    * @return address[] The pre-determined optimal path from 'fromAsset' to 'toAsset'
    */
    function getPath(address fromAsset, address toAsset) external view returns (address[] memory);

    /**
    * @dev Sets the path from 'fromAsset' to 'toAsset'
    * @notice The path is found manually before being stored in this contract
    * @param fromAsset Token to swap from
    * @param toAsset Token to swap to
    * @param newPath The pre-determined optimal path between the two assets
    */
    function setPath(address fromAsset, address toAsset, address[] calldata newPath) external;
}
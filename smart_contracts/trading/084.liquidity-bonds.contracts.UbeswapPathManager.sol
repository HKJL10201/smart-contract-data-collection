// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import "./openzeppelin-solidity/contracts/Ownable.sol";
import './interfaces/IUbeswapPathManager.sol';

contract UbeswapPathManager is IUbeswapPathManager, Ownable {
    mapping (address => mapping(address => address[])) public optimalPaths;

    constructor() Ownable() {}

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the path from 'fromAsset' to 'toAsset'
    * @notice The path is found manually before being stored in this contract
    * @param fromAsset Token to swap from
    * @param toAsset Token to swap to
    * @return address[] The pre-determined optimal path from 'fromAsset' to 'toAsset'
    */
    function getPath(address fromAsset, address toAsset) external view override assetIsValid(fromAsset) assetIsValid(toAsset) returns (address[] memory) {
        address[] memory path = optimalPaths[fromAsset][toAsset];

        require(path.length >= 2, "UbeswapPathManager: Path not found.");

        return path;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Sets the path from 'fromAsset' to 'toAsset'
    * @notice The path is found manually before being stored in this contract
    * @param fromAsset Token to swap from
    * @param toAsset Token to swap to
    * @param newPath The pre-determined optimal path between the two assets
    */
    function setPath(address fromAsset, address toAsset, address[] memory newPath) external override onlyOwner assetIsValid(fromAsset) assetIsValid(toAsset) {
        require(newPath.length >= 2, "UbeswapPathManager: Path length must be at least 2.");
        require(newPath[0] == fromAsset, "UbeswapPathManager: First asset in path must be fromAsset.");
        require(newPath[newPath.length - 1] == toAsset, "UbeswapPathManager: Last asset in path must be toAsset.");

        optimalPaths[fromAsset][toAsset] = newPath;

        emit SetPath(fromAsset, toAsset, newPath);
    }

    /* ========== MODIFIERS ========== */

    modifier assetIsValid(address assetToCheck) {
        require(assetToCheck != address(0), "UbeswapPathManager: Asset cannot have zero address.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetPath(address fromAsset, address toAsset, address[] newPath);
}
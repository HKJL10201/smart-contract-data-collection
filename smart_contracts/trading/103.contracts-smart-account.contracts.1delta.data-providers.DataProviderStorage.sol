// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "../../libraries/structs/EnumerableSet.sol";

contract DataProviderBaseStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active logic of DataProvider
     */
    address public implementation;

    /**
     * @notice Pending logic of DataProvider
     */
    address public pendingImplementation;
}

contract DataProviderStorageGenesis is DataProviderBaseStorage {
    bool public initialized;

    mapping(address => mapping(address => mapping(uint24 => address))) public v3Pools;
    mapping(address => bool) public isValidPool;

    // maps undelyings to cTokens
    mapping(address => address) internal _cTokens;

    address internal _cEther;
    // maps cTokens to underlyings
    mapping(address => address) internal _underlyings;

    mapping(address => bool) cTokenIsValid;
    address internal _comptroller;

    // These allow us to read out cTokens and underlyings in a clan manner
    EnumerableSet.AddressSet _allCTokens;
    EnumerableSet.AddressSet _allUnderlyings;

    // This allows approving weth spending on the minimal router
    address internal _nativeWrapper;
    address internal _minimalRouter;
}

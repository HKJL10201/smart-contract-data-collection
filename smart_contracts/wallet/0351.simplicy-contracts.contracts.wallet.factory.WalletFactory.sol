// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IWalletFactory} from "./IWalletFactory.sol";
import {WalletFactoryInternal} from "./WalletFactoryInternal.sol";

abstract contract WalletFactory is IWalletFactory, WalletFactoryInternal {
    /**
     * @notice set the address of the Diamond contract
     * @param diamond: the address of the Diamond contract
     */
    function setDiamond(address diamond) external override {
        _beforeSetDiamond(diamond);
        _setDiamond(diamond);
        _afterSetDiamond(diamond);
    }

    /**
     * @notice add facet to facets array
     * @param name: the name of the facet
     * @param facetAddress: the address of the facet contract
     * @param version: the version of the facet
     */
    function addFacet(
        string memory name,
        address facetAddress,
        string memory version
    ) external override {
        _beforeAddFacet(name, facetAddress, version);
        _addFacet(name, facetAddress, version);
        _afterAddFacet(name, facetAddress, version);
    }

    /**
     * @notice add a guardian into WalletFactory
     * remember: we are not adding Guardian to a user wallet in this function!
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    function addGuardian(bytes32 hashId, bytes32 guardian) external override {
        _addGuardian(hashId, guardian);
    }

    /**
     * @notice remove a guardian into WalletFactory
     * @param hashId: the hash of the identification of the guardian
     */
    function removeGuardian(bytes32 hashId) external override {
        _removeGuardian(hashId);
    }

    /**
     * @notice deploy a new wallet from WalletDiamond
     * @param hashId: the hash of the identification of the user
     * @return the address of the new wallet
     */
    function createWallet(bytes32 hashId) external override returns (address) {
        return _createWallet(hashId, msg.sender);
    }

    /**
     * @notice create a new wallet from WalletDiamond
     * @param hashId: the hash of the identification of the user
     * @param salt: salt to deterministically deploy the clone
     */
    function createWalletDeterministic(bytes32 hashId, bytes32 salt)
        external
        override
    {
        _createWalletDeterministic(hashId, salt);
    }

    /**
     * @notice predict the address of the new wallet
     * @param salt: salt to deterministically deploy the clone
     */
    function predictDeterministicAddress(bytes32 salt)
        public
        view
        override
        returns (address predicted)
    {
        return _predictDeterministicAddress(salt);
    }

    /**
     * @notice query the address of the stored diamond contract
     */
    function getDiamond() public view override returns (address) {
        return _getDiamond();
    }

    /**
     * @notice query the address of the wallet contract
     * @param hashId: the hash id of the user
     */
    function getWallet(bytes32 hashId) external view returns (address) {
        return _getWallet(hashId);
    }
}

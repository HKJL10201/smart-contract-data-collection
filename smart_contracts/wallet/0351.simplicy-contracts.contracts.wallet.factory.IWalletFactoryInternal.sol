//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title WalletFactory interface needed by internal functions
 */
interface IWalletFactoryInternal {
    /**
     * @notice emitted when anew diamond wallet is created by user
     * @param instance: the address of the instance
     */
    event NewDiamondWallet(address instance);

    /**
     * @notice emitted when Diamond address is set
     * @param wallet: the address of the wallet
     */
    event DiamondIsSet(address wallet);

    /**
     * @notice emitted when a new facet is added to WalletFactory
     * @param name: the name of the facet
     * @param facetAddress: the address of the facet contract
     * @param version: the version of the facet
     */
    event FacetIsAdded(string name, address facetAddress, string version);

    /**
     * @notice emitted when a new facet is removed to WalletFactory
     * @param facetName: name of the facet
     *
     */
    event FacetIsRemoved(string facetName);

    /**
     * @notice emitted when a guardian is added to WalletFactory
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    event GuardianAdded(bytes32 indexed hashId, bytes32 guardian);

    /**
     * @notice emitted when a guardian is removed to WalletFactory
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    event GuardianRemoved(bytes32 indexed hashId, bytes32 guardian);
}

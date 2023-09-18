// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ISolidStateDiamond} from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

library WalletFactoryStorage {
    struct Facet {
        string name;
        address facetAddress;
        string version;
    }
    struct Layout {
        mapping(bytes32 => bytes32) guardians;
        mapping(bytes32 => address) wallets;
        mapping(string => Facet) facets;
        mapping(address => uint256) indexOfErc721Token;
        address diamond;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.WalletFactory");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice set the address of the Diamond contract
     * @param diamond: the address of the Diamond contract
     */
    function setDiamond(Layout storage s, address diamond) internal {
        s.diamond = diamond;
    }

    /**
     * @notice add a new facet to facets mapping
     * @param name: the name of the facet
     * @param facetAddress: the address of the facet contract
     * @param version: the version of the facet
     */
    function addFacet(
        Layout storage s,
        string memory name,
        address facetAddress,
        string memory version
    ) internal {
        s.facets[name].name = name;
        s.facets[name].facetAddress = facetAddress;
        s.facets[name].version = version;
    }

    /**
     * @notice remove a facet from facets mapping
     * @param facetName: the name of the facet
     */
    function removeFacet(Layout storage s, string memory facetName) internal {
        delete s.facets[facetName];
    }

    /**
     * @notice add a guardian into WalletFactory
     * @param hashId: the hash of the identification of the guardian
     * @param guardian: the identityCommitment of the guardian
     */
    function addGuardian(
        Layout storage s,
        bytes32 hashId,
        bytes32 guardian
    ) internal {
        s.guardians[hashId] = guardian;
    }

    /**
     * @notice remove a guardian into WalletFactory
     * @param hashId: the hash of the identification of the guardian
     */
    function removeGuardian(Layout storage s, bytes32 hashId) internal {
        delete s.guardians[hashId];
    }

    /**
     * @notice add a wallet into WalletFactory
     * @param hashId: the hash of the identification of the wallet
     * @param wallet: the address of the wallet
     */
    function addWallet(
        Layout storage s,
        bytes32 hashId,
        address wallet
    ) internal {
        s.wallets[hashId] = wallet;
    }
}

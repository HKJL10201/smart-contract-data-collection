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
        mapping(address => uint256) indexOfErc721Token;
        address diamond;

        // facet address -> facetsIdx
        mapping(address => uint) facetIndex;
        Facet[] facets;
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
     * @notice store a new facet in WalletFactory.
     * @param name: the name of the Facet.
     * @param facetAddress: the address of the facet.
     * @param version: the version of the facet.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function storeFacet(
        Layout storage s,
        string memory name,
        address facetAddress,
        string memory version
    ) internal returns (bool){
        uint arrayIndex = s.facets.length;
        uint index = arrayIndex + 1;
        s.facets.push(
            Facet(
                name,
                facetAddress,
                version
            )
        );
        s.facetIndex[facetAddress] = index;
        return true;
    }

     /**
     * @notice delete a facet from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param facetAddress: the address of the facet.
     * @return returns a boolean value indicating whether the operation succeeded. 
     */
    function deleteFacet(
        Layout storage s,
        address facetAddress
    ) internal returns (bool) {
        uint index = s.facetIndex[facetAddress];
        require(index > 0, "WalletFactory: FACET_NOT_EXISTS");

        uint arrayIndex = index - 1;
        require(arrayIndex >= 0, "WalletFactory: ARRAY_INDEX_OUT_OF_BOUNDS");

        if(arrayIndex != s.facets.length - 1) {
            s.facets[arrayIndex] = s.facets[s.facets.length - 1];
            s.facetIndex[s.facets[arrayIndex].facetAddress] = index;
        }
        s.facets.pop();
        delete s.facetIndex[facetAddress];
        return true;
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

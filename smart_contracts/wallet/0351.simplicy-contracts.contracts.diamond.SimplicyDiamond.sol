// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { IOwnable, Ownable, OwnableInternal, OwnableStorage } from "@solidstate/contracts/access/ownable/Ownable.sol";
import { ISafeOwnable, SafeOwnable } from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";
import { ERC165, IERC165, ERC165Storage } from "@solidstate/contracts/introspection/ERC165.sol";
import { DiamondBase, DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/base/DiamondBase.sol";
import { DiamondReadable, IDiamondReadable } from "@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol";
import { DiamondWritable, IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol";

import {ISimplicyDiamond} from "./ISimplicyDiamond.sol";
import {ISemaphore} from "../semaphore/ISemaphore.sol";
import {ISemaphoreGroups} from "../semaphore/ISemaphoreGroups.sol";
import {ISemaphoreGroupsBase} from "../semaphore/base/SemaphoreGroupsBase/ISemaphoreGroupsBase.sol";
/**
 * @title Simplicy "Diamond" proxy reference implementation
 */ 
abstract contract SimplicyDiamond is 
    ISimplicyDiamond,
    DiamondBase,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable,
    ERC165
{
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    function _init(
        address semaphoreFacetAddress,
        address semaphoreGroupsFacetAddress,
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address owner_
    ) internal {
        ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
        bytes4[] memory selectors = new bytes4[](12);
        bytes4[] memory semaphoreFacetSelectors = new bytes4[](12);
        bytes4[] memory semaphoreGroupsFacetSelectors = new bytes4[](12);
        FacetCut[] memory facetCuts = new FacetCut[](3);

        // register DiamondWritable
        selectors[0] = IDiamondWritable.diamondCut.selector;

        erc165.setSupportedInterface(type(IDiamondWritable).interfaceId, true);

        // register DiamondReadable
        selectors[1] = IDiamondReadable.facets.selector;
        selectors[2] = IDiamondReadable.facetFunctionSelectors.selector;
        selectors[3] = IDiamondReadable.facetAddresses.selector;
        selectors[4] = IDiamondReadable.facetAddress.selector;

        erc165.setSupportedInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165
        selectors[5] = IERC165.supportsInterface.selector;

        erc165.setSupportedInterface(type(IERC165).interfaceId, true);

        // register SimplicyDiamond
        selectors[6] = SimplicyDiamond.getFallbackAddress.selector;
        selectors[7] = SimplicyDiamond.setFallbackAddress.selector;

        facetCuts[0] = FacetCut({
            target: address(this),
            action: IDiamondWritable.FacetCutAction.ADD,
            selectors: selectors
        });

        // register ISemaphore
        semaphoreFacetSelectors[0] = ISemaphore.verifyProof.selector;

        erc165.setSupportedInterface(type(IERC165).interfaceId, true);

        facetCuts[1] = FacetCut({
            target: semaphoreFacetAddress,
            action: IDiamondWritable.FacetCutAction.ADD,
            selectors: semaphoreFacetSelectors
        });

        // register ISemaphoreGroups
        semaphoreGroupsFacetSelectors[0] = ISemaphoreGroups.getRoot.selector;
        semaphoreGroupsFacetSelectors[1] = ISemaphoreGroups.getDepth.selector;
        semaphoreGroupsFacetSelectors[2] = ISemaphoreGroups.getNumberOfLeaves.selector;
        semaphoreGroupsFacetSelectors[3] = ISemaphoreGroupsBase.createGroup.selector;
        semaphoreGroupsFacetSelectors[4] = ISemaphoreGroupsBase.updateGroupAdmin.selector;
        semaphoreGroupsFacetSelectors[5] = ISemaphoreGroupsBase.addMembers.selector;
        semaphoreGroupsFacetSelectors[6] = ISemaphoreGroupsBase.removeMember.selector;

        erc165.setSupportedInterface(type(IERC165).interfaceId, true);
        facetCuts[2] = FacetCut({
            target: semaphoreGroupsFacetAddress,
            action: IDiamondWritable.FacetCutAction.ADD,
            selectors: semaphoreGroupsFacetSelectors
        });


        DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), "");
        
        // set owner
        OwnableStorage.layout().setOwner(owner_);

        ISemaphoreGroups(address(this)).createGroup(groupId, depth, zeroValue, owner_);
        // ISemaphoreGroups(address(this)).addMembers(groupId, identityCommitments);
    }

    receive() external payable {}

    /**
     * @inheritdoc ISimplicyDiamond
     */
    function getFallbackAddress() external view returns (address) {
        return DiamondBaseStorage.layout().fallbackAddress;
    }

    /**
     * @inheritdoc ISimplicyDiamond
     */
    function setFallbackAddress(address fallbackAddress) external {
        _beforeSetFallbackAddress(fallbackAddress);

        DiamondBaseStorage.layout().fallbackAddress = fallbackAddress;

        _afterSetFallbackAddress(fallbackAddress);
    }

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnable)
    {
        super._transferOwnership(account);
    }

    /**
     * @notice hook that is called before setFallbackAddress
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _beforeSetFallbackAddress(address fallbackAddress) internal view virtual {}

     /**
     * @notice hook that is called after setFallbackAddress
     * to learn more about hooks: https://docs.openzeppelin.com/contracts/4.x/extending-contracts#using-hooks
     */
    function _afterSetFallbackAddress(address fallbackAddress) internal view virtual { }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IGuardian} from "./IGuardian.sol";
import {GuardianInternal} from "./GuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";

/**
 * @title Guardian functions 
 */
abstract contract Guardian is IGuardian, GuardianInternal {
    /**
     * @inheritdoc IGuardian
     */
    function getGuardian(uint256 hashId) external view override returns (GuardianStorage.Guardian memory) {
        uint index = _getGuardianIndex(hashId);
        require(index > 0, "Guardian: GUARDIAN_NOT_FOUND");

        uint arrayIndex = index - 1;
        return _getGuardian(arrayIndex);
    }

    /**
     * @inheritdoc IGuardian
     */
    function getGuardians(bool includePendingAddition) public view override returns (GuardianStorage.Guardian[] memory) {
        return _getGuardians(includePendingAddition);
    }

    /**
     * @inheritdoc IGuardian
     */
    function numGuardians(bool includePendingAddition) external view override returns (uint256) {
        return _numGuardians(includePendingAddition);
    }

    /**
     * @inheritdoc IGuardian
     */
    function requireMajority(GuardianDTO[] calldata guardians) external view override {
        _requireMajority(guardians);
    }

    /**
     * @inheritdoc IGuardian
     */
    function removeGuardians(uint256[] memory guardians) external override {
        _beforeRemoveGuardians(guardians);

         for (uint i = 0; i < guardians.length; i++) {
            uint256 hashId = guardians[i];
            require(removeGuardian(hashId), "Guardian: FAILED_TO_REMOVE_GUARDIAN");
         }         
        
        _afterRemoveGuardians(guardians);
    }

    /**
     * @inheritdoc IGuardian
     */
    function cancelPendingGuardians() external override {
        // TODO: implement
    }

    /**
     * @inheritdoc IGuardian
     */
    function setInitialGuardians(uint256[] memory guardians) public override {
        _beforeSetInitialGuardians(guardians);

         for (uint i = 0; i < guardians.length; i++) {
            uint256 hashId = guardians[i];
            require(addGuardian(hashId), "Guardian: FAILED_TO_ADD_GUARDIAN");         
        }

        _afterSetInitialGuardians(guardians);
    }

     /**
     * @inheritdoc IGuardian
     */
    function addGuardian(uint256 hashId) public override returns(bool){
        _beforeAddGuardian(hashId);
        
        return _addGuardian(hashId);
    }

    /**
     * @inheritdoc IGuardian
     */
    function removeGuardian(uint256 hashId) public override returns(bool) {
        _beforeRemoveGuardian(hashId);
        
        return _removeGuardian(hashId);
    }
}

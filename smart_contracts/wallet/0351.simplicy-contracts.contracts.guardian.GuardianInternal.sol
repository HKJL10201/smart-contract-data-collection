// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

import {IGuardianInternal} from "./IGuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";
import {MIN_GUARDIANS, MAX_GUARDIANS, GUARDIAN_PENDING_PERIODS} from "../utils/Constants.sol";


/**
 * @title Guardian internal functions, excluding optional extensions
 */
abstract contract GuardianInternal is IGuardianInternal {
    using GuardianStorage for GuardianStorage.Layout;
    using SafeCast for uint;

    modifier isGuardian(uint256 hashId, bool includePendingAddition) {
        require(hashId != 0, "Guardian: GUARDIAN_HASH_ID_IS_ZERO");

        uint guardianIndex = _getGuardianIndex(hashId);
        require(guardianIndex > 0, "Guardian: GUARDIAN_NOT_FOUND");

        uint arrayIndex = guardianIndex - 1;

        GuardianStorage.Guardian memory g = _getGuardian(arrayIndex);
        require(_isActiveOrPendingAddition(g, includePendingAddition), "Guardian: GUARDIAN_NOT_ACTIVE");
        _;
    }

    modifier isMinGuardian(GuardianDTO[] calldata guardians) {
        require(guardians.length >= MIN_GUARDIANS, "Guardian: MIN_GUARDIANS_NOT_MET");
        _;
    }

    modifier isMaxGuardian(GuardianDTO[] calldata guardians) {
        require(guardians.length <= MAX_GUARDIANS, "Guardian: MAX_GUARDIANS_EXCEEDED");
        _;
    }

    /**
     * @notice internal query the mapping index of guardian.
     * @param hashId: the hashId of the guardian.
     */
    function _getGuardianIndex(uint256 hashId) internal view virtual returns (uint) {
        return GuardianStorage.layout().guardianIndex[hashId];
    }

    /**
     * @notice internal query query a guardian.
     * @param arrayIndex: the index of Guardian array.
     */
    function _getGuardian(uint arrayIndex) internal view virtual returns (GuardianStorage.Guardian memory) {
        return GuardianStorage.layout().guardians[arrayIndex];
    }

    /**
     * @notice internal function query all guardians from the storage
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function _getGuardians(bool includePendingAddition) internal view virtual returns (GuardianStorage.Guardian[] memory) {
        GuardianStorage.Guardian[] memory guardians = new GuardianStorage.Guardian[](GuardianStorage.layout().guardians.length);
        uint index = 0;
        for(uint i = 0; i < GuardianStorage.layout().guardians.length; i++) {
            GuardianStorage.Guardian memory g = GuardianStorage.layout().guardians[i];           
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                guardians[index] = g;
                index++;
            }
        }
            
        return guardians;
    }

    /**
     * @notice internal function query the length of the active guardians
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function _numGuardians(bool includePendingAddition) internal view virtual returns (uint count) {
        GuardianStorage.Guardian[] memory guardians = _getGuardians(includePendingAddition);
        for(uint i = 0; i < guardians.length; i++) {
            GuardianStorage.Guardian memory g = guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                count++;
            }
        }
    }

     function _requireMajority(GuardianDTO[] calldata signers) internal view virtual returns (bool) {
        // We always need at least one signer
        if (signers.length == 0) {
            return false;
        }
        
        uint256 lastSigner;
        // Calculate total group sizes
        GuardianStorage.Guardian[] memory allGuardians = _getGuardians(false);
        require(allGuardians.length > 0, "NO_GUARDIANS");
        for (uint i = 0; i < signers.length; i++) {
            // Check for duplicates
            require(signers[i].hashId > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i].hashId;

            bool _isGuardian = false;
            for (uint j = 0; j < allGuardians.length; j++) {
                if (allGuardians[j].hashId == signers[i].hashId) {
                    _isGuardian = true;
                    break;
                    
                }
            }
            require(_isGuardian, "SIGNER_NOT_GUARDIAN");
        }
        uint numExtendedSigners = allGuardians.length;
        return signers.length >= (numExtendedSigners >> 1) + 1;
    }

    /**
     * @notice internal function add a new guardian to the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     *
     * Emits a {GuardianAdded} event.
     */
     function _addGuardian(uint256 hashId) internal virtual returns(bool) {
        uint numGuardians = _numGuardians(true);
        require(numGuardians < MAX_GUARDIANS, "Guardian: TOO_MANY_GUARDIANS");

        uint validSince = block.timestamp;
        if (numGuardians > MIN_GUARDIANS) {
            validSince = block.timestamp + GUARDIAN_PENDING_PERIODS;
        }
        
        bool returned = GuardianStorage.layout().storeGuardian(hashId,validSince);

        require(returned, "Guardian: FAILED_TO_ADD_GUARDIAN");

        emit GuardianAdded(hashId, validSince);

        return returned;
    }

     /**
     * @notice internal function remove guardian from the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {GuardianRemoved} event.
     */
    function _removeGuardian(uint256 hashId) internal virtual returns(bool) {
        uint validUntil = block.timestamp + GUARDIAN_PENDING_PERIODS;
        uint index = _getGuardianIndex(hashId);
        uint arrayIndex = index - 1;

        GuardianStorage.Guardian memory g = GuardianStorage.layout().guardians[arrayIndex];

        validUntil = _deleteGuardian(g, validUntil);
    
        emit GuardianRemoved(hashId, validUntil);

        return true;
    }

    /**
     * @notice hook that is called before setInitialGuardians
     */
    function _beforeSetInitialGuardians(GuardianDTO[] calldata guardians) 
        internal 
        view
        virtual 
        isMinGuardian(guardians) 
        isMaxGuardian(guardians) 
    {
        for(uint i = 0; i < guardians.length; i++) {
            require(guardians[i].hashId != 0, "Guardian: GUARDIAN_HASH_ID_IS_ZERO");
            require(_getGuardianIndex(guardians[i].hashId) == 0, "Guardian: GUARDIAN_EXISTS");
        }
    }

    /**
     * @notice hook that is called after setInitialGuardians
     */
    function _afterSetInitialGuardians(GuardianDTO[] calldata guardians) internal view virtual {}

    /**
     * @notice hook that is called before addGuardian
     */
    function _beforeAddGuardian(uint256 hashId) internal view virtual {
        uint numGuardians = _numGuardians(true);
        require(numGuardians <= MAX_GUARDIANS, "Guardian: TOO_MANY_GUARDIANS");
    }

    /**
     * @notice hook that is called before removeGuardian
     */
    function _beforeRemoveGuardian(uint256 hashId) 
        internal view virtual 
        isGuardian(hashId, true)
    {}

    /**
     * @notice hook that is called before removeGuardians
     */
    function _beforeRemoveGuardians(GuardianDTO[] calldata guardians) internal view virtual {
        require(guardians.length > 0, "Guardian: NO_GUARDIANS_TO_REMOVE");
    }

    /**
     * @notice hook that is called after removeGuardians
     */
    function _afterRemoveGuardians(GuardianDTO[] calldata guardians) internal view virtual  {}


    /**
     * @notice check if the guardian is active or pending for addition
     * @param guardian: the guardian to be check.
     */
    function _isActiveOrPendingAddition(
        GuardianStorage.Guardian memory guardian,
        bool includePendingAddition
        )
        private
        view
        returns (bool)
    {
        return _isAdded(guardian) || includePendingAddition && _isPendingAddition(guardian);
    }

    /**
     * @notice check if the guardian is added
     * @param guardian: the guardian to be check.
     */
    function _isAdded(GuardianStorage.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(IGuardianInternal.GuardianStatus.ADD) &&
            guardian.timestamp <= block.timestamp;
    }

    /**
     * @notice check if the guardian is pending for addition
     * @param guardian: the guardian to be check.
     */
    function _isPendingAddition(GuardianStorage.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(IGuardianInternal.GuardianStatus.ADD) &&
            guardian.timestamp > block.timestamp;
    }

     /**
     * @notice private function delete a guardian from the storage.
     * @param g: the guardian to be deleted. 
     * @param validUntil: the timestamp when the guardian is removed.
     * @return returns validUntil. 
     */
    function _deleteGuardian(GuardianStorage.Guardian memory g, uint validUntil) private returns(uint) {
        if (_isAdded(g)) {
            g.status = uint8(IGuardianInternal.GuardianStatus.REMOVE);
            g.timestamp = validUntil.toUint64();
            require(GuardianStorage.layout().deleteGuardian(g.hashId), "Guardian: UNEXPECTED_RESULT");
            return validUntil;
        }
        if (_isPendingAddition(g)) {
            g.status = uint8(IGuardianInternal.GuardianStatus.REMOVE);
            g.timestamp = 0;
            require(GuardianStorage.layout().deleteGuardian(g.hashId), "Guardian: UNEXPECTED_RESULT");
            return 0;
        }
        return 0;
    }
}

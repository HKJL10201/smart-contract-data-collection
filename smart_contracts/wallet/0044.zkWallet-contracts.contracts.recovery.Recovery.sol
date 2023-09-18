// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IRecovery} from "./IRecovery.sol";
import {RecoveryInternal} from "./RecoveryInternal.sol";
import {RecoveryStorage} from "./RecoveryStorage.sol";

import {GuardianInternal} from "../guardian/GuardianInternal.sol";
import {GuardianStorage} from "../guardian/GuardianStorage.sol";

import {ISemaphoreInternal} from "../semaphore/ISemaphoreInternal.sol";
import {SemaphoreInternal} from "../semaphore/SemaphoreInternal.sol";

/** 
 * @title Recovery
 */
abstract contract Recovery is IRecovery, ISemaphoreInternal, RecoveryInternal, GuardianInternal, SemaphoreInternal {
    /**
     * @inheritdoc IRecovery
     */
    function getRecoveryStatus() public view virtual override returns (IRecovery.RecoveryStatus) {
        return _getStatus();
    }

    /**
     * @inheritdoc IRecovery
     */
    function getMajority() public view virtual override returns (uint256) {
        return _getMajority();
    }

    function getRecoveryNominee() public view virtual override returns (address) {
        return _getNominee();
    }

    /**
     * @inheritdoc IRecovery
     */
    function getRecoveryCounter() public view virtual override returns (uint8) {
        return _getCounter();
    }

    /**
     * @inheritdoc IRecovery
     */
    function recover(//
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        address newOwner
    ) external override {
        GuardianStorage.Guardian[] memory allGuardians = _getGuardians(false);
        uint numExtendedSigners = allGuardians.length;
        require(numExtendedSigners > 0, "Recovery: NO_GUARDIANS");
        uint256 majority = (numExtendedSigners >> 1) + 1;
        
        _beforeRecover(majority, newOwner);

        _verifyProof(groupId, signal, nullifierHash, externalNullifier, proof);
        emit ProofVerified(groupId, signal);

        _recover(majority, newOwner);

        if (RecoveryStorage.layout().counter == (numExtendedSigners >> 1) + 1) {
            _duringRecovery(majority, newOwner);

            emit Recovered(newOwner);
            _resetRecovery();
        }
        _afterRecover(majority, newOwner);
    }

    /**
     * @inheritdoc IRecovery
     */
    function resetRecovery() public virtual override {
        _beforeResetRecovery();

        _resetRecovery();

        _afterResetRecovery();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IRecoveryInternal} from "./IRecoveryInternal.sol";
import {RecoveryStorage} from "./RecoveryStorage.sol";

/** 
 * @title Recovery internal functions, excluding optional extensions
 */
abstract contract RecoveryInternal is IRecoveryInternal {
    using RecoveryStorage for RecoveryStorage.Layout;

    function _getStatus() internal view virtual returns (IRecoveryInternal.RecoveryStatus) {
        return IRecoveryInternal.RecoveryStatus(RecoveryStorage.layout().status);
    }

    function _getMajority() internal view virtual returns (uint256) {
        return RecoveryStorage.layout().majority;
    }

    function _getNominee() internal view virtual returns (address) {
        return RecoveryStorage.layout().nominee;
    }

    function _getCounter() internal view virtual returns (uint8) {
        return RecoveryStorage.layout().counter;
    }

    /**
     * @notice internal functio recover a wallet by setting a new owner,
     */
    function _recover(uint256 majority, address nominee)  internal virtual {
        RecoveryStorage.layout().counter += 1;
        
        IRecoveryInternal.RecoveryStatus status = _getStatus();
        if (status == IRecoveryInternal.RecoveryStatus.NONE) {
            RecoveryStorage.layout().setStatus(uint8(IRecoveryInternal.RecoveryStatus.PENDING));
            RecoveryStorage.layout().setMajority(majority);
            RecoveryStorage.layout().setNominee(nominee);
            emit RecoveryUpdated(IRecoveryInternal.RecoveryStatus.PENDING, majority, nominee, RecoveryStorage.layout().counter);
        }
    }

    function _resetRecovery() internal virtual {
        RecoveryStorage.layout().setStatus(uint8(IRecoveryInternal.RecoveryStatus.NONE));
        RecoveryStorage.layout().setMajority(0);
        RecoveryStorage.layout().setNominee(0x0000000000000000000000000000000000000000);
        RecoveryStorage.layout().setCounter(0);
    }

    /**
     * @notice hook that is called before recover is called
     */
    function _beforeRecover(uint256 majority, address nominee) internal view virtual {
        require(majority > 0, "Recovery: ZERO_MAJORITY");
        require(nominee != address(0), "Recovery: ZERO_NOMINEE");
        require(nominee != msg.sender, "Recovery: NOT_ALLOWED_TO_RECOVER_OWN_WALLET");
        require(_getStatus() != IRecoveryInternal.RecoveryStatus.ACCEPTED, "Recovery: REOVERY_ALREADY_ACCEPTED");
    }

    /**
     * @notice hook that is called during recovery.
     * should override this function to transfer the ownership
     */
    function _duringRecovery(uint256 majority, address nominee) internal virtual {}

    /**
     * @notice hook that is called before recover is called
     */
    function _afterRecover(uint256 majority, address nominee) internal view virtual {}

    /**
     * @notice hook that is called before resetRecovery is called
     */
    function _beforeResetRecovery() internal view virtual {}

    /**
     * @notice hook that is called after resetRecovery is called
     */
    function _afterResetRecovery() internal view virtual {}
}

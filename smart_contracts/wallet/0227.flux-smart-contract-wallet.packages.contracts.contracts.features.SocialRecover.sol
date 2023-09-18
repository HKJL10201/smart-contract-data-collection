// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract SocialRecover {
    address public recoveryAccount;

    event RecoveryAccountChanged(address account);

    modifier onlyRecoveryAccount() {
        _onlyRecoveryAccount();
        _;
    }

    function _onlyRecoveryAccount() internal view {
        //directly from EOA owner, or through the entryPoint (which gets redirected through execFromEntryPoint)
        require(
            msg.sender == recoveryAccount && msg.sender == address(this),
            "only switch account"
        );
    }

    function _setRecoveryAccount(address account) internal {
        recoveryAccount = account;
        emit RecoveryAccountChanged(account);
    }
}

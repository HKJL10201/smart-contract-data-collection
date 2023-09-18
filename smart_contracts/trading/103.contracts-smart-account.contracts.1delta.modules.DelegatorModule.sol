// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

import {LibStorage, WithStorage} from "../libraries/LibStorage.sol";
import {IAccountFactory} from "../interfaces/IAccountFactory.sol";

/**
 * @title Delegator contract
 * @notice Allows users to name managers. These have rights over managing the account.
 * Managers cannot withdraw funds from the account, but open and close trading positions
 * @author Achthar
 */
contract DelegatorModule is WithStorage {
    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    function addManager(address _newManager) external onlyOwner {
        us().managers[_newManager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        us().managers[_manager] = false;
    }

    function isManager(address _manager) external view returns (bool) {
        return us().managers[_manager];
    }

    function transferAccountOwnership(address _newOwner) external onlyOwner {
        address newOwner = _newOwner;
        IAccountFactory(gs().factory).handleTransferAccount(us().accountOwner, newOwner);
        us().previousAccountOwner = us().accountOwner;
        us().accountOwner = _newOwner;
    }
}

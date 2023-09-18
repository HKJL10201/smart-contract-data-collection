// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Manageable is OwnableUpgradeSafe {
    mapping (address => bool) public _manager;

    event ManagerChanged(address managerAddress, bool managerFlag);

    function __Manageable_init() internal initializer {
        __Ownable_init();
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(_manager[_msgSender()] == true, "Ownable: caller is not the manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    function isManager(address manager) public view returns(bool) {
        return (_manager[manager] == true);
    }

    /**
     * @dev  setManager
     */
    function setManager(address newManagerAddress) public virtual onlyOwner {
        _manager[newManagerAddress] = true;
        emit ManagerChanged(newManagerAddress, true);
    }

    /**
     * @dev  delManager
     */
    function delManager(address managerAddress) public virtual onlyOwner {
        _manager[managerAddress] = false;
        emit ManagerChanged(managerAddress, false);
    }
}
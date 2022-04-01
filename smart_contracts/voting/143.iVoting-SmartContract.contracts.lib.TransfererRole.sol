
pragma solidity ^0.5.0;

import "./Roles.sol";
import "./MasterRole.sol";


contract TransfererRole is MasterRole {
    using Roles for Roles.Role;

    event TransfererAdded(address indexed account);
    event TransfererRemoved(address indexed account);

    Roles.Role private _transferer;

    constructor () internal {
        _addTransferer(msg.sender);
    }

    modifier onlyTransferer() {
        require(isTransferer(msg.sender), "TransfererRole: caller does not have the Transferer role");
        _;
    }

    function isTransferer(address account) public view returns (bool) {
        return _transferer.has(account);
    }

    function addTransferer(address account) public onlyTransferer {
        _addTransferer(account);
    }

    function removeTransferer(address account) public onlyMaster {
        _removeTransferer(account);
    }

    function renounceTransferer() public {
        _removeTransferer(msg.sender);
    }

    function _addTransferer(address account) internal {
        _transferer.add(account);
        emit TransfererAdded(account);
    }

    function _removeTransferer(address account) internal {
        _transferer.remove(account);
        emit TransfererRemoved(account);
    }
}

    
pragma solidity ^0.5.0;

import "./Roles.sol";

contract MasterRole {
    using Roles for Roles.Role;

    event MasterAdded(address indexed account);
    event MasterRemoved(address indexed account);

    Roles.Role private _master;

    constructor () internal {
        _addMaster(msg.sender);
    }

    modifier onlyMaster() {
        require(isMaster(msg.sender), "MasterRole: caller does not have the Master role");
        _;
    }

    function isMaster(address account) public view returns (bool) {
        return _master.has(account);
    }

    function addMaster(address account) public onlyMaster {
        _addMaster(account);
    }

    function renounceMaster() public {
        _removeMaster(msg.sender);
    }

    function _addMaster(address account) internal {
        _master.add(account);
        emit MasterAdded(account);
    }

    function _removeMaster(address account) internal {
        _master.remove(account);
        emit MasterRemoved(account);
    }
}

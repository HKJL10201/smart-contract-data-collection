pragma solidity ^0.5.0;

import "./Roles.sol";
import "./MasterRole.sol";


contract MaintainerRole is MasterRole {
    using Roles for Roles.Role;

    event MaintainerAdded(address indexed account);
    event MaintainerRemoved(address indexed account);

    Roles.Role private _maintainer;

    constructor () internal {
        _addMaintainer(msg.sender);
    }

    modifier onlyMaintainer() {
        require(isMaintainer(msg.sender), "MaintainerRole: caller does not have the Maintainer role");
        _;
    }

    function isMaintainer(address account) public view returns (bool) {
        return _maintainer.has(account);
    }

    function addMaintainer(address account) public onlyMaintainer {
        _addMaintainer(account);
    }

    function removeMaintainer(address account) public onlyMaster {
        _removeMaintainer(account);
    }

    function renounceMaintainer() public {
        _removeMaintainer(msg.sender);
    }

    function _addMaintainer(address account) internal {
        _maintainer.add(account);
        emit MaintainerAdded(account);
    }

    function _removeMaintainer(address account) internal {
        _maintainer.remove(account);
        emit MaintainerRemoved(account);
    }
}

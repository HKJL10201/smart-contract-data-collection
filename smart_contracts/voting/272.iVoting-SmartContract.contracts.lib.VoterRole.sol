
pragma solidity ^0.5.0;

import "./Roles.sol";
import "./MasterRole.sol";


contract VoterRole is MasterRole {
    using Roles for Roles.Role;

    event VoterAdded(address indexed account);
    event VoterRemoved(address indexed account);

    Roles.Role private _voter;

    constructor () internal {
        _addVoter(msg.sender);
    }

    modifier onlyVoter() {
        require(isVoter(msg.sender), "VoterRole: caller does not have the Voter role");
        _;
    }

    function isVoter(address account) public view returns (bool) {
        return _voter.has(account);
    }

    function addVoter(address account) public onlyVoter {
        _addVoter(account);
    }

    function removeVoter(address account) public onlyMaster {
        _removeVoter(account);
    }

    function renounceVoter() public {
        _removeVoter(msg.sender);
    }

    function _addVoter(address account) internal {
        _voter.add(account);
        emit VoterAdded(account);
    }

    function _removeVoter(address account) internal {
        _voter.remove(account);
        emit VoterRemoved(account);
    }
}

    
pragma solidity ^0.4.19;

import './iWeightedGovernance.sol';
import './Token.sol';
import './iPoll.sol';
import './Owner.sol';

contract WeightedGovernance is Owner, iWeightedGovernance  {
    function () public {
        //if ether is sent to this address, send it back.
        revert();
    }

    address[] public groups;
    address[] public polls;

    function createGroup(string _name, string _symbol, uint256 _initialAmount, uint8 _decimalUnits) public returns (address group) {
        address newGroup = new Token(_name, _symbol, _initialAmount, _decimalUnits);
        groups.push(newGroup);
        return newGroup;
    }

    function createPoll() public returns (address existingPolls) {
        address newPoll = new Poll();
        polls.push(newPoll);
        return newPoll;
    }

    function getGroups() public view returns (address[] existingGroups) {
        return groups;
    }

    function getPolls() public view returns (address[] pools) {
        return polls;
    }
}

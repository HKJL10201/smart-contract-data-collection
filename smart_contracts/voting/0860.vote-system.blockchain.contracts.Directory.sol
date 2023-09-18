// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./Election.sol";

contract Directory {

    address[] public elections;

    event ElectionAdded(address indexed electionAddress, string electionName);
    event ElectionRemoved();

    function addElection(string memory _name, string memory _description, uint _endDate) public {
        Election election = new Election(msg.sender, _name, _description, _endDate);
        address electionAddress = address(election);
        elections.push(electionAddress);
        emit ElectionAdded(electionAddress, _name);
    }

    function removeElection(uint _index) public electionExists(_index) {
        for (uint i = _index; i < elections.length - 1; i++) {
            elections[i] = elections[i + 1];
        }
        elections.pop();
        emit ElectionRemoved();
    }

    function getElectionsNumber() public view returns (uint){
        return elections.length;
    }

    modifier electionExists(uint _index) {
        require(_index < elections.length, "Election index out of bound");
        _;
    }
}

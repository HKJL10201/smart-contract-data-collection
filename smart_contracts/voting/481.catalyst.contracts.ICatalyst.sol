//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICatalyst {
    struct Project {
        bool status;
        bool exists;
        uint votes;
    }

    event voterAssigned(address indexed voterAddress, uint8 role);

    event voterRemoved(address voterAddress);

    event RoleAdded(uint8 roleId, uint8 voteWeight);

    event ProjectAdded(string name);

    event ProjectClosed(string name);

    event VotingPointsUpdated(address voter, uint votingPoints);

    event Voted(string indexed projectName, address voter, uint amount);
}

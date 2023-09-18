// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Voting.sol";

contract MainContract {
    uint public votingId = 0;
    mapping(uint => address) public Votings;
    
    event VotingCreated(uint id);
    
    function createVoting(
        string[] memory _name, // e.g ["student group leader voting", "so it`s necessary"]
        string[][] memory _candidates // e.g [["boba", "choose me"],]
    ) public returns (uint id) {
        Voting voting = new Voting(_name, _candidates);
        Votings[votingId] = address(voting);
        id = votingId++;
        emit VotingCreated(id);
        return id;
    }
}

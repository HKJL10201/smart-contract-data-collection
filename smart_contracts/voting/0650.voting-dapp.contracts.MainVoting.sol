// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

import './Voting.sol';

contract MainVoting {
    address public owner = msg.sender;

    struct Ballot {
        address voting;
        string name;
        string description;
    }

    uint public ballotId = 0;
    mapping (uint => Ballot) public ballots;

    function createBallot (string memory _name, string memory _description) public {
        Voting voting = new Voting(_name, _description, 10, msg.sender);
        ballots[ballotId] = Ballot({
            voting: address(voting),
            name: _name,
            description: _description
        });
        ballotId++;
    }
}

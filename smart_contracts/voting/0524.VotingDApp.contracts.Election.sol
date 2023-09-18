// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    // struct candidate
    // candidate count
    // mapping candidate
    // constructor

    struct Candidate {
        uint256 id;
        string name;
        uint256 votecount;
    }

    // candidate count
    uint256 public candidatesCount;

    mapping(uint256 => Candidate) public candidates;
    // input any address of a smart contract from ether scan; address a = 0x0fC5025C764cE34df352757e82f7B5c4Df39A836

    mapping(address => bool) public votedornot;

    event electionupdated(uint256 id, string name, uint256 votecount);

    constructor() {
        // code to initiate Eg: Donald Trump and Barack Obama Election
        addCandidate("Property1");
        addCandidate("Property2");
    }

    // function to add candidates
    function addCandidate(string memory name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, 0);
    }

    function Vote(uint256 _id) public {
        // check the person has not voted again
        require(
            !votedornot[msg.sender],
            "You have already registered your vote"
        );
        // the id that the person has input is available
        require(candidates[_id].id != 0);

        // increase the vote count of the person whom the candidate votes
        candidates[_id].votecount += 1;
        // change the votedornot boolean value to true
        votedornot[msg.sender] = true;
        emit electionupdated(
            _id,
            candidates[_id].name,
            candidates[_id].votecount
        );
    }
}

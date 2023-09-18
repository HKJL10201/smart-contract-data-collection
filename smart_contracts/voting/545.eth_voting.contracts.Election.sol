// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

contract Election {

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    //Store accounts that have voted
    mapping(address => bool) public voters;

    mapping(uint => Candidate) public candidates;

    uint public candidatesCount;

    constructor() public {
        addCandidate("Donald Trump");
        addCandidate("Joe Biden");
    }
    
    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        //require that they haven't voted before
        require(!voters[msg.sender]);
        //require a valid candidate
        require(0 < _candidateId && _candidateId <= candidatesCount);
        //record that voter has voted
        voters[msg.sender] = true;
        //update candidate vote count
        candidates[_candidateId].voteCount++;
    }
}
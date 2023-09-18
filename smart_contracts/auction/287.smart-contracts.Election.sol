pragma solidity ^0.8.3;
// SPDX-License-Identifier: MIT
contract Election {

    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool authorised;
        bool voted;
        uint vote;
    }

    address public owner;
    
    string public electionName;

    mapping(address => Voter) public voters;

    Candidate[] public candidates;
    uint public totalVote;

    constructor(string memory _name) {
        owner = msg.sender;
        electionName = _name;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function addCandidate(string memory _name) ownerOnly public {
        candidates.push(Candidate(_name, 0));
    }

    function getCandidateCount() public view returns(uint) {
        return candidates.length;
    }

    function authorise(address _person) ownerOnly public {
        voters[_person].authorised = true;
    }

    function vote(uint _candidateIndex) public {
        require(!voters[msg.sender].voted);
        require(voters[msg.sender].authorised);

        voters[msg.sender].vote = _candidateIndex;
        voters[msg.sender].voted = true;

        candidates[_candidateIndex].voteCount += 1;
        totalVote += 1;
    }
}
// SPDX-License-Identifier: UNLICENED
pragma solidity ^0.7.5;

contract Election {

    address public ElectionController;
    string public ElectionName;

    constructor(string memory _ElectionName) {
        ElectionController = msg.sender;
        ElectionName = _ElectionName;
    }
    
    modifier OnlyElectionController {
        require(ElectionController == msg.sender, "you are not the ElectionController.");
        _;
    }

    struct Candidate {
        string Name;
        uint id;
        uint voteCount;
    }

    mapping(uint => Candidate) public Candidates;

    struct Voter {
        bool authorized;
        bool voted;
        uint vote;
    }

    mapping(address => Voter) public voters;

    uint public CandidatesCount;

    function addCandidates(string memory Name) public OnlyElectionController {
        CandidatesCount++;
        Candidates[CandidatesCount] = Candidate(Name, CandidatesCount, 0);
    }

    function Authorized(address voter) public OnlyElectionController {
        voters[voter].authorized = true;
    }

    function vote(uint candidateId) public {
        voters[msg.sender].voted = true;

        voters[msg.sender].vote = candidateId;

        Candidates[candidateId].voteCount++;
    }

}
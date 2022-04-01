pragma solidity ^0.5.1;

contract Voting {
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    mapping(address => bool) public voters;
    mapping (uint=>Candidate) public candidates;
    uint public candidatesCount;

    // Constructor
    constructor() public {
        AddCandidate("Candidate One");
        AddCandidate("Candidate Two");
    }

    function AddCandidate(string memory _name) private{
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
    }

    function vote (uint _candidateId) public{

        require(!voters[msg.sender]);
        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        // record that voter has voted
        voters[msg.sender] = true;
        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
    }

}
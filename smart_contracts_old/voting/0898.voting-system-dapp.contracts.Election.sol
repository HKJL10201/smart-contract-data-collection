pragma solidity ^0.8.12;

contract Election{

    // Structure of Candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    //Storing Candidate
    //similar to maps in C++ (hashmaps)
    mapping(uint => Candidate) public candidates;
    //Number of Candidates
    uint public candidatesCount;

    //Store accounts that have voted
    mapping(address=>bool) public voters;

    // Constructor
    constructor() public{
        //constructor
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        //require that they haven't voted before
        require(!voters[msg.sender], "You already voted!");
        require(_candidateId>0 && _candidateId<=candidatesCount, "Out of candidates list!");
        //record the voted accounts
        voters[msg.sender] = true;
        //update candidate vote Count
        candidates[_candidateId].voteCount++;
    }

}
pragma solidity ^0.4.2;


contract Election {

    //Model a candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    //Store accounts that have voted
    mapping(address => bool) public voters;

    //Store Candidates
    mapping(uint => Candidate) public candidates;

    //Fetch Candidate
    //Store Candidates Count
    uint public candidatesCount;

    //Voted event
    event votedEvent (
        uint indexed _candidateId
    );

    //Constructor
    constructor() public {
        addCandidate("Kristian");
        addCandidate("Giovana");
        addCandidate("Guillermo");
    }

    //Add candidate
    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
        //require that address has not voted 
        require(!voters[msg.sender], " this account has voted already!");

        //require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, " invalid candidate!");

        //Record that voter as voted 
        voters[msg.sender] = true;

        //Update candidate vote count
        candidates[_candidateId].voteCount ++;

        //Trigger voted event
        votedEvent(_candidateId);
    }
}

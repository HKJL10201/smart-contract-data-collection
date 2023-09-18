pragma solidity ^0.5.0;

contract Election {
    //Model the candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    //Store accounts that have voted
    mapping(address=>bool) public voters;
    //Store Canditates
    //Fetch Candidate
    mapping(uint => Candidate) public candidates;
    //Store Candidates Count
    uint public candidatesCount;

    //user voted event
    event votedEvent(
        uint indexed _candidateId
    );

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private{
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        //require that they haven't voted before
        require(!voters[msg.sender], "Voter has already voted");
        //require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Candidate doesn't exist");
        //record a voter has voted
        voters[msg.sender] = true;
        //update candidate count
        candidates[_candidateId].voteCount++;

        //trigger event
        emit votedEvent(_candidateId);
    } 
}

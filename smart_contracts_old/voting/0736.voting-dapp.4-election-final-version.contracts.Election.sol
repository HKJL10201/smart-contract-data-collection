pragma solidity ^0.5.0;

contract Election {
     //Model a candidate
     struct Candidate{
         uint id;
         string name;
         uint voteCount;
     }
     //store accounts that haave voted
     mapping(address => bool) public voters;
     //Store candidate
     //Fetch candidate
     mapping(uint => Candidate) public candidates;
     //Store candidate Count
    uint public candidatesCount;
    //voted event
    event votedEvent(
        uint indexed _candidateId
    );
    constructor() public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    } 
    function  addCandidate (string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
    function vote(uint _candidateId) public {
        //require that they haven't voted before
        require(!voters[msg.sender],"already voted");
        //require a valid cndidate
        require(_candidateId > 0 && _candidateId <= candidatesCount,"invalid candidate");

        //record that voter has voted
        voters[msg.sender] = true;
        //update candidate vote count
        candidates[_candidateId].voteCount++;
        //trigger voted event
        emit votedEvent(_candidateId);
    }
}
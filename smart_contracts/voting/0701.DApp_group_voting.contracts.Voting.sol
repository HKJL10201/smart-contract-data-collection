pragma solidity ^0.5;
contract Voting {

   struct Candidate {
    uint id;
    string name;
    uint voteCount;
    }

// Declare voted event 
event votedEvent (
        uint indexed _candidateId
    );

mapping(uint => Candidate) public candidates;

mapping(address => bool) public voters;

uint public candidatesCount;

constructor() public{
        addCandidate("Candidate_1");
        addCandidate("Candidate_2");
    }

function addCandidate (string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // function to allow voting
function vote (uint _candidateId) public { 

    // require that they haven't voted before 
    require(!voters[msg.sender]); 
    // require a valid candidate 
    require(_candidateId > 0 && _candidateId <= candidatesCount); 
    // record that voter has voted 
    voters[msg.sender] = true; 
    // update candidate vote Count 
    candidates[_candidateId].voteCount++;
    // trigger voted event
    emit votedEvent(_candidateId);
} 

}

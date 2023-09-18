pragma solidity ^0.4.2;

contract Election {
   //Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    //Store accounts that have voted
    mapping(address => bool) public voters;
   //Store Candidate
   //Fetch Candidate
    mapping(uint => Candidate) public candidates;
   //Store Candidates counts
    
    uint public candidatesCount;

    function Election () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
       
    }

    function addCandidate(string _name) private{
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public {
          //Require that they haven't voted before
        require(!voters[msg.sender]);
          //require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
         //Record that voter has voted
        voters[msg.sender] = true;

         // update candidate vote Count
        candidates[_candidateId].voteCount++;
        
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

contract Election{
     //Model a candidate 
     struct Candidate{
          uint id;
          string name;
          uint voteCount;
     }
     //Store Candidate
     mapping(uint=>Candidate) public candidates;
     //Store voters
     mapping(address=>bool) public voters;
     //Fetch candidate
     uint public countCandidates;
     //Store candidate count
     constructor () public {
          addCandidate("Souvik");
          addCandidate("Sayan");
     }
     function addCandidate(string memory _name) private {
          countCandidates++;
          candidates[countCandidates] = Candidate(countCandidates, _name, 0);
     }

     function vote(uint _candidateid) public{
          //require that they haven't voted before
          require(!voters[msg.sender]);
          //require that the candidate is valid
          require(_candidateid > 0 && _candidateid <=countCandidates);
          
          //track of vote counts
          voters[msg.sender] = true;

          //giving vote
          candidates[_candidateid].voteCount ++;
     }
     
}
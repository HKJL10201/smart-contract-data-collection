// SPDX-License-Identifier: MIT
pragma solidity  <= 0.8.12;

contract Election {
  //Structure of candidate standing in the election
  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }
  //Storing candidates in a map
  mapping(uint => Candidate) public candidates;
  //Number of candidates in standing in the election
  uint public candidatesCount;
  //Storing address of those voters who already voted
  mapping (address => bool) public voters;
   //Adding 2 candidates during the deployment of contract
  constructor () {
    addCandidate("Candidate 1");
    addCandidate("Candidate 1");
  }
  // private function to add candidate
  function addCandidate(string memory _name) private {
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }

  //public Function to vote for a candidate
  function vote(uint _candidateId) public {
    //Checking if the voter has already voted
    require(!voters[msg.sender], "You have already voted!");
    //Checking if the candidate id is valid
    require(_candidateId <= candidatesCount, "Candidate does not exist!");
    //Incrementing the vote count of the candidate
    candidates[_candidateId].voteCount++;
    //Adding the voter to the voters list
    voters[msg.sender] = true;
  }
}
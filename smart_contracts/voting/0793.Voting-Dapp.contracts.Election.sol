pragma solidity 0.5.8;
contract Election {
     // string public candidate;
     struct Candidate{
          uint id;
          string name;
          uint voteCount;
     }

constructor() public{
     addCandidate("Candidate 1");
     addCandidate("Candidate 2");
}
mapping(uint => Candidate) public candidates;
uint public candidatesCount;
function addCandidate(string memory _name) private{
     candidatesCount++;
     candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
}
}
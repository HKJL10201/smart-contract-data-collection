pragma solidity >=0.4.21 <0.7.0;

contract Election {

  string public candidate;
  uint public candidatesCount;

  struct Candidate {
    uint id;
    string name;
    uint voteCount;
  }

  // mapping actualy doesn't know how many are stored in them, so seperately maitain the number of candidates.
  mapping(uint => Candidate) public Candidates;
  mapping(address => bool) public voters;

  constructor () public {
    addCandidate('Candidate 1');
    addCandidate('Candidate 2');
  }

  function addCandidate(string memory _name) private {
    candidatesCount++;
    Candidates[candidatesCount] = Candidate(candidatesCount,_name,0);
  }

  function vote(uint _candidateId) public{
    require(!voters[msg.sender],"voter already voted");
    require(_candidateId>0 && _candidateId<=candidatesCount, "not a valid candidate");
    voters[msg.sender] = true;
    Candidates[_candidateId].voteCount++;
  }

}


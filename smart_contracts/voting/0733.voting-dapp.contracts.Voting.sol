pragma solidity^0.4.23;

//define smart contract
contract Voting{

  //Define candidates
  struct Candidate{
    uint id;
    string name;
    uint NumVotes;
  }

  //Record votes

  //Find candidates
  mapping(uint8 => Candidate) public candidates;

  uint8 public candidatesCount;
  //Define constructor
  constructor() public{
    addCandidate("BLP");
    addCandidate("DLP");
    addCandidate("UPP");
  }

  function addCandidate(string _name) private{
    candidatesCount++;
    candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
  }



}
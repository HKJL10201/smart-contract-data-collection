pragma solidity >=0.4.21 <0.7.0;

contract Voting {
  address public contractOwner;

  struct Candidate{
      uint id;
      string name;
      uint votes;
  }


  mapping(uint => Candidate) public candidates;
  uint public candidatesCount = 0;

  event votedEvent(uint indexed _candidateId);

  mapping(address => bool) public voted;


  modifier restricted() {
    if (msg.sender == contractOwner) 
    _;
  }

  constructor() public {
    contractOwner = msg.sender;
    addCandidate("Tolu");
    addCandidate("Limitless");
    addCandidate("Boss");
  }

function addCandidate(string memory _candidateName) private restricted {
  candidatesCount++;
  candidates[candidatesCount] = Candidate(candidatesCount,_candidateName,0);
}

function vote(uint _candidateId) public {
  //require that voter hasn't voted previously.
   require(!voted[msg.sender]);
  //require that candidate is valid.
   require(_candidateId > 0 && _candidateId <= candidatesCount);
  //increment candidate's vote count.
  candidates[_candidateId].votes++;
  //add voter to voted list.
  voted[msg.sender] = true;
  //emit votedEvent
  emit votedEvent(_candidateId);

  }
}
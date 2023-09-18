pragma solidity ^0.5.11;

contract ZKPElections {

  address public contractOwner;

  struct Candidate {
    uint name;
    uint voteCount;
  }
 
  struct Election {
    uint name;
    address owner;
    bool isClosed;
        
    mapping (uint => Candidate) candidates;
    uint candidateCount;

    // 0: NoStatus 1: AwaitingVote 2: VoteCast
    mapping (address => uint8) voterToStatus;
    uint voterCount;
  }
 
  mapping (uint => Election) public elections;
  uint public electionCount;

  event ElectionAdded(uint name, uint _electionKey);
  event ElectionClosed(uint _electionKey);
  event VoteCast(uint _electionKey, uint _candidateKey);

  constructor () public {
    contractOwner = msg.sender;
  }

  function getContractOwner() external view returns (address) {
    return contractOwner;
  }
  
  function withdrawAllFunds() external {
    require(msg.sender == contractOwner);
    msg.sender.transfer(address(this).balance);
  }
  
  function addElection(uint _name,
		       uint [] calldata _candidates,
		       address [] calldata _voterAddresses) external payable {
        
    require(_candidates.length >= 1);
    require(_voterAddresses.length >= 1);
        
    electionCount += 1;
    Election storage election = elections[electionCount];

    election.name = _name;
    election.owner = msg.sender;
    election.isClosed = false;
    election.candidateCount = _candidates.length;
    election.voterCount = _voterAddresses.length;
        
    for (uint i = 1; i <= _candidates.length; i ++ ) {
      for (uint j = 1; j <= _candidates.length; j ++) {
	election.candidates[j].name = _candidates[j-1];
      }
      for (uint j = 1; j <= _voterAddresses.length; j ++) {
	election.voterToStatus[_voterAddresses[j-1]] = 1;
      }           
    }

    emit ElectionAdded(_name, electionCount);
  }

  function getNextElectionKey() external view returns (uint) {
    return electionCount + 1;
  }
  
  function getElection(uint _electionKey)
    external view returns (uint, uint [] memory, uint [] memory, uint, bool) {
        
    require (_electionKey <= electionCount);
        
    Election storage election = elections[_electionKey];
    uint cnt = election.candidateCount;
    uint [] memory cands = new uint[](cnt);
    uint [] memory vCnts = new uint[](cnt);
        
    for (uint i = 1; i <= cnt; i ++ ) {
      cands[i-1] = election.candidates[i].name;
      vCnts[i-1] = election.candidates[i].voteCount;
    }
        
    return (election.name, cands, vCnts, election.voterCount, election.isClosed);
  }

  function getElectionKeysForOwner()
    external view returns (uint [] memory) {

    uint [] memory keys = new uint [] (electionCount);
   
    for (uint i = 1; i <= electionCount; i ++) {
      if (elections[i].owner == msg.sender) {
	keys[i-1] = 1;
      }
    }

    return keys;
  }
 
  function getVoterStatus(uint _electionKey)
    external view returns (uint8) {

    require(_electionKey <= electionCount);
    return elections[_electionKey].voterToStatus[msg.sender];
  }


  function castVote(uint _electionKey, uint _candidateKey) external {
    require(_electionKey <= electionCount);
        
    Election storage election = elections[_electionKey];
    require(!election.isClosed);
    require(election.voterToStatus[msg.sender] == 1);
    require(_candidateKey <= election.candidateCount);
        
    election.candidates[_candidateKey].voteCount += 1;
    election.voterToStatus[msg.sender] = 2;

    emit VoteCast(_electionKey, _candidateKey);

    // Last vote closes election
    uint votesCast;
    for (uint i = 1; i <= election.candidateCount; i ++ ) {
      votesCast += election.candidates[i].voteCount;
    }
    if (votesCast == election.voterCount) {
      election.isClosed = true;
      emit ElectionClosed(_electionKey);
    }
  }
    
  function closeElectionPrematurely(uint _electionKey) external {

    // Premature election closing only by owner
    require (_electionKey <= electionCount);
    Election storage election = elections[_electionKey];
    require (election.owner == msg.sender);
    require(!election.isClosed);
    election.isClosed = true;
        
    emit ElectionClosed(_electionKey);
  }
}

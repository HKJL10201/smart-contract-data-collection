pragma solidity ^0.4.2;

contract VoteDapp {
  
  struct Candidate {
    uint voteCount;
    string name;
  }
    
  uint public startTime;
  address public owner;
  Candidate[] private candidates;
  
  event CandidateAdded(address indexed _from, string name);
 
  // Constractor
  function VoteDapp() public {
    owner = msg.sender;
    startTime = now;
  }

  function addCandidate(string _name) public {
    candidates.push(Candidate(0, _name));
    CandidateAdded(msg.sender, _name);
  }

  function submitVote(uint256 index) public {
    candidates[index].voteCount++;
  }

  function getCandidatesCount() public constant returns (uint256 nbrCandidates) {
    return candidates.length;
  }
  
  function getCandidate(uint index) public constant returns(uint, string) {
    return (candidates[index].voteCount, candidates[index].name);
  }
  
  function getWinner() public constant returns (uint voteCount, string name) {
     uint winnerIndex = 0;
     
     for (uint x = 0; x < candidates.length; x++) {
        if (candidates[x].voteCount > candidates[winnerIndex].voteCount) {
            winnerIndex = x;
        }
    }
    
    return (candidates[winnerIndex].voteCount,candidates[winnerIndex].name);
  }
}


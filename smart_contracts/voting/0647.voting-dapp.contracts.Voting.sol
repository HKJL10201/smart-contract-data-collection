//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Voting {
  string[] private candidates;
  mapping(string => uint256) private  candidateVoteRecord;
  mapping(address => bool) private voterHistory;
  mapping(address => string) private voterToCandidateRecord;

  function addCandidate(string calldata name) external {
    if(candidateVoteRecord[name] == 0){
        candidates.push(name);
        candidateVoteRecord[name] = 0;
    }
    
  }

  function vote(string calldata name) external {
    if (!voterHistory[msg.sender]) {
      voterToCandidateRecord[msg.sender] = name;
      candidateVoteRecord[name] += 1;
      voterHistory[msg.sender] = true;
    }
  }

  function getCandidates() public view returns(string[] memory){
      return candidates;
  }

  function getCandidateVotes(string calldata name) public view returns(uint){
      return candidateVoteRecord[name];
  }



  function getMyVote() public view returns(string memory){
      return voterToCandidateRecord[msg.sender];
  }
}

pragma solidity ^0.8.0;

contract Voting {
  mapping(address => bool) public hasVoted;
  mapping(bytes32 => uint256) public voteCount;

  function vote(bytes32 candidate) public {
    require(!hasVoted[msg.sender], "You have already voted.");
    voteCount[candidate]++;
    hasVoted[msg.sender] = true;
  }

  function getVoteCount(bytes32 candidate) public view returns (uint256) {
    return voteCount[candidate];
  }
}

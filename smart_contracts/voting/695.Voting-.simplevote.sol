pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/SafeMath.sol";

contract Candidates {
  using SafeMath for uint;

  struct Candidate {
    uint votes;
    string name;
  }

  Candidate[] public candidates;

  // Keep track of total number of votes
  uint public totalVotes;

  constructor() public {
    // Add candidates to the array
    candidates.push(Candidate({
      votes: 0,
      name: "Candidate 1"
    }));
    candidates.push(Candidate({
      votes: 0,
      name: "Candidate 2"
    }));
  }

  // Function to allow people holding a specific NFT to cast their vote
  function vote(uint candidateIndex) public {
    // Ensure that the given candidate index is valid
    require(candidateIndex < candidates.length, "Invalid candidate index");

    // Increment the candidate's vote count
    candidates[candidateIndex].votes = candidates[candidateIndex].votes.add(1);

    // Increment the total vote count
    totalVotes = totalVotes.add(1);
  }

  // Function to get the total number of votes for a given candidate
  function getVoteCount(uint candidateIndex) public view returns (uint) {
    // Ensure that the given candidate index is valid
    require(candidateIndex < candidates.length, "Invalid candidate index");

    return candidates[candidateIndex].votes;
  }
}

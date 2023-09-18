pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/SafeMath.sol";

contract Candidates {
  using SafeMath for uint;

  struct Candidate {
    uint votes;
    string name;
  }

  // Keep track of all candidates
  Candidate[] public candidates;

  // Keep track of total number of votes
  uint public totalVotes;

  // Keep track of the NFT address
  address public nftAddress;

  // Event to emit when someone votes
  event Voter(address indexed voter);

  constructor(address _nftAddress) public {
    // Set the NFT address
    nftAddress = _nftAddress;

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
    // Ensure that the caller is holding the required NFT
    require(
      ERC721(_nftAddress).balanceOf(msg.sender) > 0,
      "You must hold the required NFT to vote"
    );

    // Ensure that the given candidate index is valid
    require(candidateIndex < candidates.length, "Invalid candidate index");

    // Increment the candidate's vote count
    candidates[candidateIndex].votes = candidates[candidateIndex].votes.add(1);

    // Increment the total vote count
    totalVotes = totalVotes.add(1);

    // Emit event to indicate that someone has voted
    emit Voter(msg.sender);
  }

  // Function to get the total number of votes for a given candidate
  function getVoteCount(uint candidateIndex) public view returns (uint) {
    // Ensure that the given candidate index is valid
    require(candidateIndex < candidates.length, "Invalid candidate index");

    return candidates[candidateIndex].votes;
  }

  // Function to get the name of a candidate
  function getCandidateName(uint candidateIndex) public view returns (string) {
    // Ensure that the given candidate index is valid
    require(candidateIndex < candidates.length, "Invalid candidate index");

    return candidates[candidateIndex].name;
  }

  // Function to get the total number of votes for all candidates
  function getTotalVotes() public view returns (uint) {
    return totalVotes;
  }
}

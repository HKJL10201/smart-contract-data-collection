pragma solidity ^0.4.17;

import "./Ownable.sol";

contract Ballot is Ownable {

    struct Candidate {
        bytes32 name;
        bytes32 party;
        uint voteCount;
    }

    struct Voter {
        uint weight;
        bool voted;
        uint vote;
    }

  address public governor;

  mapping(address => Voter) public voters;

  Candidate[] public candidates;

  function Ballot(bytes32[] candidateNames, bytes32[] candidateParties) public {
      governor = msg.sender;
      voters[governor].weight = 1;

      for (uint i = 0; i < candidateNames.length; i++) {
        candidates.push(Candidate({
            name: candidateNames[i],
            party: candidateParties[i],
            voteCount: 0
        }));
      }
  }

  function getCandidates() public view returns(bytes32[]) {
      uint length = candidates.length;

      bytes32[] memory names = new bytes32[](length);

      for (uint i = 0; i < length; i++) {
        names[i] = candidates[i].name;
      }

      return names;

  }

  function getCandidate(uint index) public view returns(bytes32) {
      return candidates[index].name;
  }

  function giveRightToVote(address voter) onlyOwner public {
      require(!voters[voter].voted && (voters[voter].weight == 0));
      voters[voter].weight = 1;
  }

  function vote(uint candidate) public {
      Voter storage sender = voters[msg.sender];
      require(!sender.voted);
      sender.voted = true;
      sender.vote = candidate;

      candidates[candidate].voteCount += sender.weight;
  }

  function winningCandidate() public view
          returns (uint winningCandidate)
  {
      uint winningVoteCount = 0;
      for (uint p = 0; p < candidates.length; p++) {
          if (candidates[p].voteCount > winningVoteCount) {
              winningVoteCount = candidates[p].voteCount;
              winningCandidate = p;
          }
      }
  }

    function winnerName() public view
            returns (bytes32 winnerName)
    {
        winnerName = candidates[winningCandidate()].name;
    }

    function getNumber() public pure returns(uint aValue) { aValue = 444; }
}
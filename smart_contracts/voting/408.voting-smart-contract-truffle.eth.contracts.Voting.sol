// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract Voting {
  mapping (address => address[]) public votes;

  struct Voter {
    string name;
    string role;
    bool voted;
    address id;
  }

  Voter[] public voters;
  Voter[] public candidates;

  function registerAsVoter(string memory voterName) public {
    bool voterFlag = false;
    for(uint index = 0; index < voters.length; index++) {
      if(keccak256(abi.encodePacked(voters[index].name)) == keccak256(abi.encodePacked(voterName))) {
        voterFlag = true;
        break;
      }
    }
    require(!(voterFlag == true), "Voter is already registered");
    Voter memory voter;
    voter.name = voterName;
    voter.role = "voter";
    voter.voted = false;
    voter.id = msg.sender;
    voters.push(voter);
  }

  function registerAsCandidate() public {
    address inputVoterAddress = msg.sender;
    uint index = 0;
    bool voterFlag = false;
    bool candidateFlag = false;
    Voter memory voter;
    for(index = 0; index < voters.length; index++) {
      if(voters[index].id == inputVoterAddress) {
        voter = voters[index];
        voterFlag = true;
        break;
      }
    }
    require(!(voterFlag == false), "Voter is not registered");
    for(index = 0; index < candidates.length; index++) {
      if(candidates[index].id == voter.id) {
        candidateFlag = true;
        break;
      }
    }
    require(!(candidateFlag == true), "Candidate is already registered");
    voter.role = "candidate";
    voters[index] = voter;
    candidates.push(voter);
  }

  function castVote(address inputCandidate) public {
    address inputVoterAddress = msg.sender;
    bool voterFlag = false;
    bool candidateFlag = false;
    Voter memory voter;
    Voter memory candidate;
    uint voterIndex = 0;
    for(uint index = 0; index < voters.length; index++) {
      if(voters[index].id == inputVoterAddress) {
        voter = voters[index];
        voterIndex = index;
        voterFlag = true;
      }
      if(voters[index].id == inputCandidate) {
        candidate = voters[index];
        candidateFlag = true;
      }
    }
    require(!voterFlag == false, "Voter is not registered");
    require(!voter.voted == true, "Voter has already voted");
    require(!candidateFlag == false, "Candidate is not present in voters list");
    require(!!(keccak256(abi.encodePacked(candidate.role)) == keccak256(abi.encodePacked("candidate"))), "Candidate is not registered");
    votes[inputCandidate].push(inputVoterAddress);
    voter.voted = true;
    voters[voterIndex] = voter;
  }

  function getVoters() public view returns (Voter[] memory) {
    return voters;
  }

  function getVotesOf(address candidate) public view returns (address[] memory) {
    return votes[candidate];
  }

  function getCandidates() public view returns (Voter[] memory) {
    return candidates;
  }

  function getCandidateVotesCount(address candidate) public view returns (uint) {
    return votes[candidate].length;
  }
}
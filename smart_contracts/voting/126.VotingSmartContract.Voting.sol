//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Voting {
  
  address owner;
  string[] public candidateList;
  mapping (string => uint8) votesReceived;
  mapping(address => Voter) voters;

  struct Voter {
    uint time;
    address addr;
    bool voted;
  }

  constructor(string[] memory candidateNames) {
    candidateList = candidateNames;
    owner = msg.sender;
  }

  modifier ownerOnly {
    require(msg.sender == owner, "Only Admin can register voters");
    _;
  }

  function registerVoter(address voter) external ownerOnly returns(bool) {
    require(notAlreadyRegistered(voter), "Already registered");
    voters[voter] = Voter(block.timestamp, voter, false);
    return true;
  }

  // This function returns the total votes a candidate has received so far
  function totalVotesFor(string memory candidate) view public returns (uint8) {
    require(validCandidate(candidate), "Candidate Not valid");
    return votesReceived[candidate];
  }

  // This function increments the vote count for the candidate. This
  // is equivalent to casting a vote
  function voteForCandidate(string memory candidate) public {
    require(validCandidate(candidate));
    require(hasNotVoted(msg.sender), "You have already Voted");
    voters[msg.sender].voted = true;
    //votersWhoVoted.push(msg.sender);
    votesReceived[candidate] += 1;
  }

  function validCandidate(string memory candidate) view internal returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (keccak256(abi.encodePacked(candidateList[i])) == keccak256(abi.encodePacked(candidate))) {
        return true;
      }
    }
    return false;
  }

  function notAlreadyRegistered(address addr) view internal returns (bool){
    if(voters[addr].time != 0) {
      return false;
    } else {
      return true;
    }
  }

  function hasNotVoted(address voter) view internal returns (bool){
    Voter memory voterObj = voters[voter];
    require(voterObj.time != 0, "You have not registered");
    require(voterObj.voted == false, "You have already voted");
    return true;
  }
}
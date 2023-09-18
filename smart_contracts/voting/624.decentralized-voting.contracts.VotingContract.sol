pragma solidity ^0.4.22;

contract VotingContract {

  address private owner;

  mapping (bytes32 => uint8) public votesReceived;
  mapping (address => bool) private addressVoted;
  mapping (address => bool) private voterAddress;

  bytes32[] public candidateList;
  address[] public voterList;
  uint public candidateCount;

  constructor (bytes32[] candidateNames, uint count) payable public {
    candidateList = candidateNames;
    candidateCount = count;
    owner = msg.sender;
  }

  function addVoter(address voter) public returns (bool) {
    assert(msg.sender == owner);
    voterAddress[voter] = true;
    voterList.push(voter);
    return true;
  }

  function getCandidate(uint index) view public returns (bytes32) {
    return candidateList[index];
  }

  function getCandidates() view public returns(bytes32[]) {
    return candidateList;
  }

  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(bytes32 candidate) payable public {
    require(validCandidate(candidate));
    require(addressVoted[msg.sender] == false);
    require(voterAddress[msg.sender] == true);
    votesReceived[candidate] += 1;
    addressVoted[msg.sender] = true;
    //msg.sender.transfer(1);
  }

  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}

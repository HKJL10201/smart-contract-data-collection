pragma solidity ^0.4.24;

contract Voting {
  mapping (bytes32 => uint8) public votesReceived;
  bytes32[] public candidateList;
  mapping(address=>bool) public votersList;

  constructor(bytes32[] _candidateNames) public{
    candidateList = _candidateNames;
  }
  
  event voteEvent(bytes32 candidate);
  event voterEvent(address voter);
  function totalVotesFor(bytes32 candidate) public view returns (uint8) {
    //if (validCandidate(candidate) == false) throw;
      require(validCandidate(candidate));
      return votesReceived[candidate];
  }
  function voteForCandidate(bytes32 candidate) public {
    //if (validCandidate(candidate) == false) throw;
    //require(validCandidate(candidate));
    //require(!votersList[_voterAddress]);
    votesReceived[candidate] += 1;
    votersList[msg.sender]=true;
    emit voteEvent(candidate);
    emit voterEvent(msg.sender);
  }

  function validCandidate(bytes32 candidate) public view returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
  
  function getAllCandidates()public view returns(bytes32[]){
      return candidateList;
  }
}
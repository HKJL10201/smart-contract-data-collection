pragma solidity ^0.5.0;

contract Voting {
 
  mapping (bytes32 => uint8) public votesReceived;  //uint8默认是0
 
  bytes32[] public candidateList;   //动态数组存储候选人 

 
  constructor() public {
    candidateList[0] = 'Rama';
    candidateList[1] = 'Nick';
    candidateList[2] = 'Jose';
  }
  
  //插入候选人，插入成功则刷新列表
  function addCandidate(bytes32 candidate) public returns (bool){
      candidateList[candidateList.length] = candidate;

  }
 
  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }
 
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
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
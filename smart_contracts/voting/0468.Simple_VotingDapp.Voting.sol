pragma solidity ^0.4.23;

contract Voting {
  //contrauctor to initialize candidiates
  //vote for candidiates
  //get count of votes for each candidiates
  
  bytes32[] public candidateList;
  mapping (bytes32 => uint8) voteReceived;
 
  constructor(bytes32[] candidateNames) public {
      candidateList = candidateNames;
  }
  
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    voteReceived[candidate]+=1;
  }
  
  function totalVotesFor(bytes32 candidate) view public returns(uint8) {
     return voteReceived[candidate];
  }
  
  function validCandidate(bytes32 candidate) view public returns(bool) {
     for(uint8 i=0;i<candidateList.length;i++){
        if(candidateList[i] == candidate){
            return true;
        }
     }
     return false;
  }
}
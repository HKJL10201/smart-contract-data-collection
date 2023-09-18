pragma solidity ^0.4.11;

contract Voting{
   bytes32[] candidates;
   address owner;

   mapping(bytes32 => uint8) votesForCandidates;

   function Voting(bytes32[] initialCandidates){
      candidates = initialCandidates;
      owner = msg.sender;
   }

   function checkCandidateExists(bytes32 candidate) constant returns(bool){
      for(uint i = 0; i < candidates.length; i++){
         if(candidates[i] == candidate) return true;
      }
      return false;
   }

   function voteCandidate(bytes32 candidate){
      assert(checkCandidateExists(candidate) == true);
      votesForCandidates[candidate] += 1;
   }

   function getVotesCandidate(bytes32 candidate) constant returns(uint8){
      assert(checkCandidateExists(candidate) == true);
      return votesForCandidates[candidate];
   }

   function createCandidate(bytes32 candidate){
      assert(checkCandidateExists(candidate) == false);
      candidates.push(candidate);
   }

   function getAllCandidates() constant returns(bytes32[]){
      return candidates;
   }
}

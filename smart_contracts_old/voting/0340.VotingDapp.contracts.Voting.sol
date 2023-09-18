pragma solidity ^0.4.0;

contract Voting {

    //initialize a few candidates
    //vote for candidate
    //lookup vote count for each candidate
    bytes32[] public candidateNames;
    mapping (bytes32 => uint8) public votesReceived;

    function voting(bytes32[] _candidateNames) public {
        candidateNames = _candidateNames;
    }
    
    function voteForCandidate(bytes32 _candidateName) public { 
        votesReceived[_candidateName]+= 1;        
    }
    
    function totalVotesFor(bytes32 _candidateName) view public returns(uint8) {
        return votesReceived[_candidateName];
    }
    
    function validCandidate(bytes32 _candidateName) view public returns(bool) {
        for(uint i =0; i<candidateNames.length; i++) {
            if(candidateNames[i] == _candidateName) {
                return true;
            }
        }
        return false;
    }
}

pragma solidity ^0.4.18;

contract Vote {
    
    bytes32[] private candidateList;
    
    mapping(bytes32 => uint8)       	private votesReceived;
    
    function Vote(bytes32[] candidateNames) public {
        candidateList = candidateNames;
    }
    
    function getVotesforCandidate(bytes32 candidateName) public view returns (int) {
        if(candidateIsValid(candidateName)) {
            return votesReceived[candidateName];
        }
        return -1;
    }
    
    function getCandidates() public view returns (bytes32[]) {
        return candidateList;
    }
    
    function voteForCandidate(bytes32 candidateName) public {
        if(candidateIsValid(candidateName)) {
            votesReceived[candidateName] += 1;
        }
    }
    
    function candidateIsValid(bytes32 candidateName) public view returns (bool) {
        uint i;
        for(i = 0; i < candidateList.length; i++) {
            if(candidateName == candidateList[i]) {
                return true;
            }
        }
        return false;
    }
    
}
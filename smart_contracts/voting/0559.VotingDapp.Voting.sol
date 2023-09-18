pragma solidity ^ 0.4.25;

contract Voting {
    mapping (bytes32 => uint8) public votesReceived;

    bytes32[] public candidateList;

    constructor (bytes32[] memory candidateNames) public {
        candidateList = candidateNames;
    }

    function totalVotesFor(bytes32 candidate) public view returns (uint8) {
        return votesReceived[candidate];
    }

    function votesForCandidate(bytes32 candidate) public {
        if(validCandidate(candidate) == false) revert("Candidate not valid!!");
        votesReceived[candidate] += 1;
    }
    function validCandidate(bytes32 candidate) public view returns (bool) {
        for(uint i = 0; i<candidateList.length; i++){
            if(candidateList[i] == candidate){
                return true;
            }
        }
        return false;
    }

}
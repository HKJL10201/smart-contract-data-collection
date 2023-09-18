pragma solidity ^0.4.18;

contract Vote {
    bytes32[50] public candidateList;
    uint public counter;
    mapping(bytes32 => uint) public votes;

    function Vote() public {
        counter = 0;
    }
    
    function addCandidate(bytes32 candidateName) public {
        //require(validCandidate(candidateName));
        candidateList[counter] = candidateName;
        votes[candidateName] = 0;
        counter++;
    }

    function voteForCandidate(bytes32 candidateName) public {
        votes[candidateName]++;
    }

    function getCandidates() public constant returns(bytes32[50]) {
        return candidateList;
    }

    function getLastCandidate() public constant returns(bytes32) {
        return candidateList[counter-1];
    }

    function getNumberOfVotes(bytes32 candidateName) public constant returns(uint) {
        return votes[candidateName];
    }
    /*
    function validCandidate(bytes32 candidate) private view returns(bool) {
        for (uint index = 0; index < candidateList.length; index++) {
            if (keccak256(candidate) == keccak256(candidateList[index]) ) {
                return false;
            }
        }
        return true;
    }
    */
}
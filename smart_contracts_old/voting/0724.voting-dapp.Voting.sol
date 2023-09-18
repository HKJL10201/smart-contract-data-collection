pragma solidity >=0.4.0;

contract Voting {

    mapping (bytes32 => uint256) public votesReceived;

    bytes32[] public candidateList;

    constructor(bytes32[] memory candidateNames) public {
        candidateList = candidateNames;
    }

    // This function returns the total votes a candidate has received
    function totalVotesFor(bytes32 candidate) view public returns (uint256) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    // This function increments the vote count for the specified candidate.
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
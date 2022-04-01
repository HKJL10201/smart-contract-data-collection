pragma solidity ^0.4.18;

contract Voting {

    // solidity's dictionary
    mapping(bytes32 => uint8) public votesReceived;

    bytes32[] public candidateList;

    //constructor
    function Voting(bytes32[] candidateNames) public {
        candidateList = candidateNames;
    }

    // Return total votes for candidate
    function totalVotesFor(bytes32 candidate) view public returns (uint8) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    // add votes to a candidate
    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate));
        votesReceived[candidate] += 1;
    }

    // check to see if a candidate is valid
    function validCandidate(bytes32 candidate) public returns (bool) {
        for (uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}

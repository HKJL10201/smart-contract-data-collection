pragma solidity >=0.4.21 <0.6.0;

contract Voting {
    mapping(bytes32 => uint256) public votesReceived;

    bytes32[] public candidateList;

    constructor(bytes32[] memory candidateNames) public {
        candidateList = candidateNames;
    }

    function casteVote(bytes32 candidateName) public {
        require(checkValidCandidate(candidateName), "Invalid candidate");
        votesReceived[candidateName] += 1;
    }

    function countVote(bytes32 candidateName) public view returns (uint256) {
        require(checkValidCandidate(candidateName), "Invalid candidate");
        return votesReceived[candidateName];
    }

    function checkValidCandidate(bytes32 candidateName) public view returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidateName) {
                return true;
            }
        }

        return false;
    }
}
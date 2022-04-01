pragma solidity ^0.6.4;

contract Voting {
    mapping (bytes32 => uint256) public resultVoting;
    bytes32[] public candidates;

    constructor(bytes32[] memory candidates_) public {
        candidates = candidates_;
    }

    function readResultVoting(bytes32 candidate) public view returns (uint256) {
        require(isCandidateValid(candidate));
        return resultVoting[candidate];
    }

    function giveVote(bytes32 candidate) public {
        require(isCandidateValid(candidate));
        resultVoting[candidate] += 1;
    }

    function isCandidateValid(bytes32 candidate) public view returns (bool) {
        for (uint i = 0; i < candidates.length; ++i) {
            if (candidates[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}
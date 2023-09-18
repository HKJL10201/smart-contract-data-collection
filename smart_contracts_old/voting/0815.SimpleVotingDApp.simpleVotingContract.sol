pragma solidity ^0.6.4;

contract MyVotingContract {

    mapping(bytes32 => uint256) public votesCandidateMap;
    bytes32[] public candidateList;
    
    constructor(bytes32[] memory candidates) public {
        candidateList = candidates;
    }

    function totalVotesFor(bytes32 candidate) view public returns (uint256) {
        return votesCandidateMap[candidate];
    }

    function countVoteFor(bytes32 candidate) public {
        votesCandidateMap[candidate] += 1;
    }
}
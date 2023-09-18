// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.6 <0.9.0;

contract voting{

    address public pollCreator;
    mapping(bytes32=>uint256) private candidateToVotes;
    bytes32[] public candidateList;
    mapping(address=>bool) private voterToVotedOrNot;

    // This constructor sets pollCreator and list of candidates
    constructor(bytes32[] memory candidateNames) public{
        pollCreator=msg.sender;
        candidateList = candidateNames;
    }

    modifier OnlyPollCreator{
        require(msg.sender==pollCreator);
        _;
    }

    function validCandidate(bytes32 candidate) private view returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }

    function validVoter(address voter) private view returns (bool) {
        return voterToVotedOrNot[voter]==false;
    }

    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate));
        require(validVoter(msg.sender));
        candidateToVotes[candidate] += 1;
        voterToVotedOrNot[msg.sender]=true;
    }

    function totalVotesFor(bytes32 candidate) OnlyPollCreator view public returns (uint256) {
        require(validCandidate(candidate));
        return candidateToVotes[candidate];
    }

    function voterToVotedOrNotList(address voter) OnlyPollCreator view public returns (bool) {
        return voterToVotedOrNot[voter];
    }

}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingMachine is Ownable {
    mapping(string => uint256) public candidateToVotes;
    mapping(string => bool) private candidates;
    mapping(address => bool) private hasVoted;

    function addCandidate(string memory _candidate) public onlyOwner {
        candidates[_candidate] = true;
    }

    modifier canVote(address _voter) {
        require(hasVoted[_voter] == false, "You can't vote more than once!!");
        _;
    }

    function voteCandidate(string memory _candidate)
        public
        canVote(msg.sender)
    {
        if (candidates[_candidate]) {
            candidateToVotes[_candidate] = candidateToVotes[_candidate] + 1;
            hasVoted[msg.sender] = true;
        }
    }
}

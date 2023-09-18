// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import './interface/IVotingPoll.sol';

contract VotingPoll is IVotingPoll {
    
    address public immutable override factory;
    string public title;

    Candidate[] public candidates;
    mapping(address => Voter) public voters;

    constructor(){factory = msg.sender;}

    function createPoll(string calldata _title, string[] calldata _candidates) external override {
        title = _title;
        for (uint i = 0; i < _candidates.length; i++) {
            candidates.push(Candidate({
                name: _candidates[i],
                voteCount: 0
            }));
        }
    }

    function fetchCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    function vote(uint candidate) public override {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidate;
        candidates[candidate].voteCount += 1;
    }

    function hasVote(address _address) external view returns (bool) {
        Voter storage sender = voters[address(_address)];
        return sender.voted;
    }

    function winningCandidate() public override view returns (uint _winningCandidate) {
        uint winningVoteCount = 0;

        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                _winningCandidate = p;
            }
        }
    }

    function winnerName() public override view returns (string memory _winnerName) {
        _winnerName = candidates[winningCandidate()].name;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

error alreadyVoted();
error alreadyCandidate();

contract Voting {
    address[] private s_candidates;
    mapping(address => uint) private s_votes;
    mapping(address => string) private s_names;
    address[] private s_voters;

    function becomeCandidate(string memory _candidateName) public {
        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (msg.sender == s_candidates[i]) {
                revert alreadyCandidate();
            }
        }
        s_candidates.push(msg.sender);
        s_votes[msg.sender] = 0;
        s_names[msg.sender] = _candidateName;
    }

    function Vote(address _candidate) public checkCandidate(_candidate) {
        for (uint256 i = 0; i < s_voters.length; i++) {
            if (msg.sender == s_voters[i]) {
                revert alreadyVoted();
            }
        }
        s_votes[_candidate]++;
        s_voters.push(msg.sender);
    }

    function getVotes(
        address _candidate
    ) public view checkCandidate(_candidate) returns (uint256) {
        return s_votes[_candidate];
    }

    function getCandidates(uint256 index) public view returns (address) {
        require(s_candidates.length > index, "There is no such candidate");
        return s_candidates[index];
    }

    function getCandidateName(
        address _candidate
    ) public view checkCandidate(_candidate) returns (string memory) {
        return s_names[_candidate];
    }

    modifier checkCandidate(address _candidate) {
        bool notCandidate;
        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (_candidate == s_candidates[i]) {
                notCandidate = true;
            }
        }
        require(notCandidate, "There is no such candidate");
        _;
    }
}

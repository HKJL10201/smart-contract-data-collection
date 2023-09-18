//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VoterRoll.sol";

contract VoteContract is VoterRoll {
    // Candidate names are stored as strings

    string[] candidates;
    mapping (string => uint256) candidateVotes;

    constructor(string[] memory _candidates) {
        candidates = _candidates;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setCandidates(string[] memory _newCandidateList) external onlyOwner {
        candidates = _newCandidateList;
        for (uint256 i = 0; i < candidates.length; i++) {
            // Initialize all votes to 0
            string memory candidate = candidates[i];
            candidateVotes[candidate] = 0;
        }
    }

    modifier candidateExists(string memory _candidate) {
        bool exists = false;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (_compareStrings(_candidate, candidates[i])) {
                exists = true;
                break;
            }
        }
        require(exists, "Candidate does not exist");
        _;
    }

    function vote(string memory candidate) external candidateExists(candidate) voterIsEnrolled hasNotVoted {
        candidateVotes[candidate]++;
        _mark_voter_voted(msg.sender);
    }

    function viewCandidates() external view returns (string[] memory) {
        return candidates;
    }

    function viewCandidateVotes(string memory _candidate) external view returns (uint256) {
        return candidateVotes[_candidate];
    }
}

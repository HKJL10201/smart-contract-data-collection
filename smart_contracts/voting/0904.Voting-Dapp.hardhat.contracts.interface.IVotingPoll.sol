// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IVotingPoll {
    struct Candidate {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool voted;
        uint vote;
    }

    function factory() external view returns(address);

    function createPoll(string calldata _title, string[] calldata _candidates) external;

    function vote(uint candidate) external;

    function winningCandidate() external view returns (uint _winningCandidate);

    function winnerName() external view returns (string memory _winnerName);
}
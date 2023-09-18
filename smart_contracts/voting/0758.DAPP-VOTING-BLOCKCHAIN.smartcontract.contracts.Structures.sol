// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Structures{
        struct CandidateDetails {
        uint256 citizenship_number;
        uint256 totalVotes;
        string name;
        string email;
        string party;
        string electionType;
        string position;
    }

    struct VoterDetails {
        uint256 citizenship_number;
        string name;
        string email;
        uint256 limitCount;
    }

    struct BallotDetails {
        uint256 voter_id;
        uint256 candidate_id;
    }

    struct WinnerDetails{
        uint256 mayorWinnerId;
        uint256 deputyWinnerId;
        uint256 wardWinnerId;
    }
}

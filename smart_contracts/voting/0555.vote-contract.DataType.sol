// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DataType {
    struct CandidateNoId {
        bytes32 name;
        bytes32 description;
        bytes32 imageName;
    }

    struct Candidate {
        uint256 id;
        bytes32 name;
        bytes32 description;
        bytes32 imageName;
    }

    struct VotingStatus {
        uint256 id;
        bytes32 name;
        uint256 count;
    }
}
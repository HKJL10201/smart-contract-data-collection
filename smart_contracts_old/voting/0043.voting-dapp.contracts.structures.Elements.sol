//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

struct Creator {
    address id;
    string name;
}

struct ProposalForm {
    string name;
    uint256 goal; // vote count
    uint256 createdAt; // timestamp
    bool isActive;
    uint256 lastVotedAt; // timestamp
    uint256 voteCount;
    Creator createdBy;
    // mapping(uint => Proposal) voteCount;
}

struct Voter {
    string name;
    uint256 age;
    bool hasVoted;
    uint256 proposalId;
}

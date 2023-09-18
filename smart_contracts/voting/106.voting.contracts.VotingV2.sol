// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Voting {
    using Counters for Counters.Counter;
    Counters.Counter private _electionIds;

    struct Candidate {
        address wallet;
        string name;
        bool candidate;
        uint256 votes;
        uint256 electionId;
    }

    struct Voter {
        address wallet;
        bool voter;
    }

    struct Election {
        uint256 id;
        uint256 registerPeriodInitialTime;
        uint256 registerPeriodFinishTime;
        uint256 votePeriodInitialTime;
        uint256 votePeriodFinishTime;
    }

    mapping(address => Candidate) candidates;
    mapping(address => Voter) voters;
    mapping(uint256 => Election) elections;

    Candidate[] allCandidates;
    Election[] allElections;

    function createElection(uint256 registerPeriod, uint256 votePeriod) public {
        uint256 newElectionId = _electionIds.current();

        elections[newElectionId] = Election(newElectionId, block.timestamp, registerPeriod, registerPeriod, votePeriod);
        allElections.push(Election(newElectionId, block.timestamp, registerPeriod, registerPeriod, votePeriod));

        _electionIds.increment();
    }

    function applyToCandidate(string memory _name, uint256 electionId) public {
        require(
            elections[electionId].registerPeriodFinishTime > block.timestamp,
            "Register Period time finished"
        );

        require(
            !candidates[msg.sender].candidate,
            "Sender has been already been candidated"
        );

        candidates[msg.sender] = Candidate(msg.sender, _name, true, 0, electionId);
        allCandidates.push(Candidate(msg.sender, _name, true, 0, electionId));
    }

    function vote(address candidate, uint256 electionId) public {
        require(
            elections[electionId].registerPeriodFinishTime < block.timestamp,
            "Register Period not finished"
        );

        require(!voters[msg.sender].voter, "Sender has already voted");

        candidates[candidate].votes += 1;
        voters[msg.sender].voter = true;
    }

    function getAllElections() public view returns (Election[] memory) {
        Election[] memory mElections = new Election[](allElections.length);

        for (uint256 i = 0; i < allElections.length; i++) {
            mElections[i] = elections[allElections[i].id];
        }

        return mElections;
    }

    function getVotePeriodFinishTime(uint256 electionId) public view returns (uint256) {
        return elections[electionId].votePeriodFinishTime;
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory mCandidates = new Candidate[](allCandidates.length);

        for (uint256 i = 0; i < allCandidates.length; i++) {
            mCandidates[i] = candidates[allCandidates[i].wallet];
        }

        return mCandidates;
    }
}

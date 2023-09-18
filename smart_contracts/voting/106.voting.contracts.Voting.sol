// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Voting {
    struct Candidate {
        address wallet;
        string name;
        bool candidate;
        uint256 votes;
    }

    uint256 registerPeriodInitialTime;
    uint256 registerPeriodFinishTime;
    uint256 votePeriodInitialTime;
    uint256 votePeriodFinishTime;

    mapping(address => Candidate) candidates;
    mapping(address => bool) voters;

    Candidate[] allCandidates;

    constructor(uint256 registerPeriod, uint256 votePeriod) {
        registerPeriodInitialTime = block.timestamp;
        registerPeriodFinishTime = registerPeriod;
        votePeriodInitialTime = registerPeriod;
        votePeriodFinishTime = votePeriod;
    }

    function applyToCandidate(string memory _name) public {
        require(
            registerPeriodFinishTime > block.timestamp,
            "Register Period time finished"
        );

        require(
            !candidates[msg.sender].candidate,
            "Sender has been already been candidated"
        );

        candidates[msg.sender] = Candidate(msg.sender, _name, true, 0);
        allCandidates.push(Candidate(msg.sender, _name, true, 0));
    }

    function vote(address candidate) public {
        require(
            registerPeriodFinishTime < block.timestamp,
            "Register Period not finished"
        );

        require(!voters[msg.sender], "Sender has already voted");

        candidates[candidate].votes += 1;
        voters[msg.sender] = true;
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory mCandidates = new Candidate[](allCandidates.length);

        for (uint256 i = 0; i < allCandidates.length; i++) {
            mCandidates[i] = candidates[allCandidates[i].wallet];
        }

        return mCandidates;
    }

    function getVotePeriodFinishTime() public view returns (uint256) {
        return votePeriodFinishTime;
    }
}

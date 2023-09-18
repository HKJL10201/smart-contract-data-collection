// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Vote {
    struct Candidate {
        string fullName;
        uint voteCount;
        string candidateId;
    }

    struct Voter {
        address voterAddress;
        bool hasVoted;
    }

    uint256 public totalVotes;
    uint public startDate;
    uint public endDate;

    Candidate[] public candidates;

    Voter[] public voters;

    constructor() {
        addCandidates("Xi Jinping", 0, "xj000");
        addCandidates("Vladmir Putin", 0, "vp001");
        addCandidates("Joe Biden", 0, "jb002");

        addVoter(0xC5e503F9c813050D28395c21474C008702F55b9e);
        addVoter(0xe85fEDd65Bdf8f0B156CdD4502127053f3f0ed4f);

        totalVotes = 0;

        startDate = 1689055200; // July 11, 2023, 8:00:00 AM (UTC)
        endDate = 1689228000; // July 13, 2023, 8:00:00 AM (UTC)
    }

    modifier checkVotes() {
        require(totalVotes < voters.length, "Total votes exeed voters.");
        _;
    }

    function addCandidates(
        string memory _fullName,
        uint _voteCount,
        string memory _candidateId
    ) private {
        candidates.push(Candidate(_fullName, _voteCount, _candidateId));
    }

    function addVoter(address _address) private {
        voters.push(Voter(_address, false));
    }

    function findVoter(address _address) private view returns (Voter storage) {
        for (uint i = 0; i < voters.length; i++) {
            if (voters[i].voterAddress == _address) {
                return voters[i];
            }
        }
        revert("Voter address is not authorized.");
    }

    function isWithinDateRange() public view returns (bool) {
        uint currentTime = block.timestamp;
        return (currentTime >= startDate && currentTime <= endDate);
    }

    function vote(string memory _candidateId) public checkVotes {
        require(isWithinDateRange(), "All votes are closed");

        Voter storage voter = findVoter(msg.sender);
        require(!voter.hasVoted, "You have already voted.");
        voter.hasVoted = true;

        for (uint i = 0; i < candidates.length; i++) {
            if (
                keccak256(abi.encodePacked(candidates[i].candidateId)) ==
                keccak256(abi.encodePacked(_candidateId))
            ) {
                candidates[i].voteCount++;
                totalVotes++;
            }
        }
    }
}

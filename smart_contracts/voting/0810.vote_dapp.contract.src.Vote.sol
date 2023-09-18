// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct VoteModal {
    string title;
    uint256 startTime;
    uint256 duration;
    string[] selections;
}

contract Vote {
    VoteModal[] public votes;
    mapping(uint256 => mapping(address => uint256)) private userVotes;
    mapping(uint256 => uint256[]) private voteSelectionCount;

    function createVote(
        string memory title,
        uint256 startTime,
        uint256 duration,
        string[] memory selections
    ) external {
        require(selections.length > 1, "invalid selections");
        votes.push(VoteModal(title, startTime, duration, selections));
        voteSelectionCount[votes.length - 1] = new uint256[](selections.length);
    }

    function vote(uint256 voteIndex, uint256 selection) external {
        require(total() > voteIndex, "invalid voteIndex");
        VoteModal memory _vote = votes[voteIndex];
        uint256 endTime = _vote.startTime + _vote.duration;
        require(
            block.timestamp > _vote.startTime && block.timestamp < endTime,
            "not during voting time"
        );
        userVotes[voteIndex][msg.sender] = selection;
        voteSelectionCount[voteIndex][selection] += 1;
    }

    function total() public view returns (uint) {
        return votes.length;
    }

    function getVoteSelectionCount(
        uint256 voteIndex
    ) public view returns (uint256[] memory) {
        return voteSelectionCount[voteIndex];
    }
}

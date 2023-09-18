// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Data members for every contest
struct NftSubmission {
    address payable creator;
    string URL;
}

struct Contest {
    address payable winner;
    uint256 prizePool;
    uint256 entranceFee;
    uint256 startTime;
    uint256 endTime;
    uint256 numSubmissions;
    mapping(address => uint256) upvotesReceived;
    mapping(address => uint256) upvotesAlloted;
    mapping(uint256 => NftSubmission) nftSubmissions;
}

// Platform that runs the contests
contract Dapp {
    uint256 public numContests;
    mapping(uint256 => Contest) public contests;
    // Each user owns keys to contests
    mapping(address => uint256[]) public userContests;

    // Users create contests
    function createContest(
        uint256 prizePool,
        uint256 entranceFee,
        uint256 startTime,
        uint256 endTime
    ) public {
        Contest storage c = contests[++numContests];
        c.prizePool = prizePool;
        c.entranceFee = entranceFee;
        c.startTime = startTime;
        c.endTime = endTime;
        userContests[msg.sender].push(numContests);
    }

    // Users enter contests with a URL to their NFT
    function enterContest(uint256 contestId, string memory nftURL) public payable {
        Contest storage c = contests[contestId];
        require(msg.value >= c.entranceFee, "Entrance fee not met");
        require(block.timestamp >= c.startTime, "Contest must have started");
        require(c.endTime >= block.timestamp, "Contest cannot have ended");
        // Add user's nftURL to the contest
        NftSubmission storage nft = c.nftSubmissions[++c.numSubmissions];
        nft.creator = payable(msg.sender);
        nft.URL = nftURL;
        c.upvotesAlloted[msg.sender] = 1;
        c.prizePool += msg.value;
    }

    // Every Contest user can vote on 1 project
    function vote(address payable receiver, uint256 contestId) public {
        Contest storage c = contests[contestId];
        require(c.upvotesAlloted[msg.sender] == 1, "Must be a Contest participant with upvotes remaining");
        require(receiver != msg.sender, "You cannot vote for yourself");
        require(c.endTime >= block.timestamp, "Contest cannot have ended");
        c.upvotesAlloted[msg.sender] = 0;
        c.upvotesReceived[receiver] += 1;
        // Update Contest winner if necessary
        if (c.upvotesReceived[receiver] > c.upvotesReceived[c.winner]) {
            c.winner = receiver;
        }
    }

    // Users claim contest prize pool if they won
    function claim(uint256 contestId) public {
        Contest storage c = contests[contestId];
        require(msg.sender == c.winner, "Must be contest winner");
        require(c.endTime <= block.timestamp, "Contest must have ended");
        uint256 prizePool = c.prizePool;
        c.prizePool = 0;
        c.winner.transfer(prizePool);
    }

    // Get nft submissions for a contest
    function getContestSubmissions(uint256 contestId, uint256 nftId) public view returns (NftSubmission memory) {
        Contest storage c = contests[contestId];
        NftSubmission storage nft = c.nftSubmissions[nftId];
        return nft;
    }
}

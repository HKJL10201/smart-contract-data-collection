// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract WavePortal {
    uint256 totalVotes;
    uint256 noSelection;
    uint256 candidate1;
    uint256 candidate2;
    uint256 candidate3;

    event NewVote(address indexed from, uint256 timestamp, string message);

    struct Vote {
        address voter;
        string message;
        uint256 timestamp;
    }

    Vote[] votes;

    constructor() {
        console.log("This is a smart contract based voting system");
    }

    function voteNone(string memory _message) public {
        noSelection += 1;
        totalVotes += 1;
        console.log("%s voted w/ message %s", msg.sender, _message);
        votes.push(Vote(msg.sender, _message, block.timestamp));
        emit NewVote(msg.sender, block.timestamp, _message);
    }
    function voteCandidate1(string memory _message) public {
        candidate1 += 1;
        totalVotes += 1;
        console.log("%s voted w/ message %s", msg.sender, _message);
        votes.push(Vote(msg.sender, _message, block.timestamp));
        emit NewVote(msg.sender, block.timestamp, _message);
    }
    function voteCandidate2(string memory _message) public {
        candidate2 += 1;
        totalVotes += 1;
        console.log("%s voted w/ message %s", msg.sender, _message);
        votes.push(Vote(msg.sender, _message, block.timestamp));
        emit NewVote(msg.sender, block.timestamp, _message);
    }
    function voteCandidate3(string memory _message) public {
        candidate3 += 1;
        totalVotes += 1;
        console.log("%s voted w/ message %s", msg.sender, _message);
        votes.push(Vote(msg.sender, _message, block.timestamp));
        emit NewVote(msg.sender, block.timestamp, _message);
    }
    function getAllVotes() public view returns (Vote[] memory){
        return votes;
    }
    function getCandidate1Votes() public view returns (uint256) {
        return candidate1;
    }
    function getCandidate2Votes() public view returns (uint256) {
        return candidate2;
    }
    function getCandidate3Votes() public view returns (uint256) {
        return candidate3;
    }
    function getNoneVotes() public view returns (uint256) {
        return noSelection;
    }
    function getTotalVotes() public view returns (uint256) {
        console.log("The total vote counts of the candidates are:");
        console.log("Total Votes for Candidate 1:", candidate1);
        console.log("Total Votes for Candidate 2:", candidate2);
        console.log("Total Votes for Candidate 3:", candidate3);
        console.log("Total Votes for None of the candidates:", noSelection);
        return totalVotes;
    }
}


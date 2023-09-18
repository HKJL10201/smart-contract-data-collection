//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Voting {
    mapping(address => bool) public hasVoted;
    uint256 public totalVotes;
    address[] private votedAddresses;

    function vote() public {
        require(!hasVoted[msg.sender], "Already voted.");
        hasVoted[msg.sender] = true;
        totalVotes++;
        votedAddresses.push(msg.sender);
    }

    function getVotedAddresses() public view returns (address[] memory) {
        return votedAddresses;

    }
}

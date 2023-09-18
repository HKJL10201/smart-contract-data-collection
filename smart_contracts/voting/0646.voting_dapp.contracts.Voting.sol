// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/hardhat/console.sol";

contract Voting {
    struct Candidate {
        string name;
        uint votes;
    }

    uint startTime;
    address owner;
    Candidate[] candidates;
    string[] candidateNames;
    mapping(address => bool) voteLookup;

    constructor() {
        startTime = block.timestamp;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only onwer of the contract can add candidate"
        );
        _;
    }

    function addCandidate(string memory name) public onlyOwner {
        candidates.push(Candidate({name: name, votes: 0}));
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function vote(address account, uint index) public {
        require(voteLookup[account] == false, "you have voted already !!!");
        require(
            index < candidateNames.length,
            "please provide a valid index !!"
        );
        voteLookup[account] = true;
        candidates[index].votes += 1;
    }
}

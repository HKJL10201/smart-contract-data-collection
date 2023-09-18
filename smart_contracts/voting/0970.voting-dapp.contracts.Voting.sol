// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Voting {
    mapping (address => bool) public voters;
    address owner;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    uint256 public votingStart;
    uint256 public votingEnd;

    constructor(string[] memory _candidateNames, uint256 _durationInMinutes) {
        for(uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(Candidate({
                name: _candidateNames[i],
                voteCount: 0
            }));
        }
        owner = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function addCandidate(string memory _name) public onlyOwner {
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));
    }

    function vote(uint256 _candidateIndex) public {
        require(!voters[msg.sender], "You have already voted!");
        require(_candidateIndex < candidates.length, "Invalid candidate Index");

        candidates[_candidateIndex].voteCount++;
        voters[msg.sender] = true;
    }

    function getAllVotesofCandidates() public view returns(Candidate[] memory) {
        return candidates;
    }

    function getVotingStatus() public view returns(bool) {
        return(block.timestamp >= votingStart && block.timestamp < votingEnd);
    }

    function getRemainingTime() public view returns(uint256) {
        require(block.timestamp >= votingStart, "Voting has not started yet!");
        return block.timestamp >= votingEnd ? 0 : votingEnd - block.timestamp;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Vote {
    struct Candidate {
        bool initalized;
        string name;
        uint256 numVotes;
    }

    string public name;
    bool public initalized;
    string[] public candidateNames;
    uint256 public startTime;
    uint256 public regEnd;
    uint256 public voteStart;
    uint256 public voteEnd;
    mapping(address => bool) public hasVoted;
    mapping(string => Candidate) public candidates;

    constructor(
        string memory _name,
        uint256 _regEnd,
        uint256 _voteStart,
        uint256 _voteEnd
    ) {
        require(
            _regEnd > block.timestamp,
            "Registration end is set in the past!"
        );
        require(_voteStart > block.timestamp, "Vote start is set in the past!");
        require(_voteEnd > block.timestamp, "Vote end is set in the past!");
        require(
            _voteStart > _regEnd,
            "Vote start is set before registration end!"
        );
        require(_voteEnd > _voteStart, "Vote end is set before vote start!");

        name = _name;
        startTime = block.timestamp;
        regEnd = _regEnd;
        voteStart = _voteStart;
        voteEnd = _voteEnd;
        initalized = true;
    }

    function addCandidate(string memory _name) external {
        require(block.timestamp <= regEnd, "Registration has ended!");
        require(!candidates[_name].initalized, "Candidate is already entered!");

        candidates[_name] = Candidate(true, _name, 0);
        candidateNames.push(_name);
    }

    function getCandidates() external view returns (string[] memory) {
        return candidateNames;
    }

    function vote(string memory _name) external {
        require(block.timestamp >= voteStart, "Voting has not started!");
        require(block.timestamp < voteEnd, "Voting has ended!");
        require(!hasVoted[msg.sender], "You have already voted!");
        hasVoted[msg.sender] = true;

        candidates[_name].numVotes++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    mapping(address => bool) public voters;
    struct Choice {
        uint256 id;
        string name;
        uint256 votes;
    }
    struct Ballot {
        uint256 id;
        string name;
        Choice[] choices;
        uint256 end;
    }
    mapping(uint256 => Ballot) public ballots;
    uint256 public nextBallotId;
    address public admin;
    mapping(address => mapping(uint256 => bool)) public votes;

    constructor() {
        admin = msg.sender;
    }

    function addVoters(address[] calldata _voters) external onlyAdmin {
        for (uint256 i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }

    function createBallot(
        string calldata _name,
        string[] calldata _choices,
        uint256 _offset
    ) external onlyAdmin {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = _name;
        ballots[nextBallotId].end = block.timestamp + _offset;

        for (uint256 i = 0; i < _choices.length; i++) {
            ballots[nextBallotId].choices.push(Choice(i, _choices[i], 0));
        }

        nextBallotId++;
    }

    function vote(uint256 _ballotId, uint256 _choiceId) external {
        require(voters[msg.sender] == true, "only voters can vote");
        require(
            votes[msg.sender][_ballotId] == false,
            "voter can only vote once for a ballot"
        );
        require(
            block.timestamp < ballots[_ballotId].end,
            "can only vote until ballot end date"
        );
        votes[msg.sender][_ballotId] = true;
        ballots[_ballotId].choices[_choiceId].votes++;
    }

    function results(uint256 _ballotId)
        external
        view
        returns (Choice[] memory)
    {
        require(
            block.timestamp >= ballots[_ballotId].end,
            "cannot see the ballot result before ballot end"
        );
        return ballots[_ballotId].choices;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
}

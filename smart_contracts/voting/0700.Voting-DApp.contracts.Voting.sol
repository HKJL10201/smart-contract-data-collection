//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

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

    constructor() public {
        admin = msg.sender;
    }

    function getBallot(uint256 id) external view returns (Ballot memory) {
        return ballots[id];
    }

    function addVoters(address[] calldata _voters) external onlyAdmin() {
        for (uint256 i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }

    function createBallot(
        string memory name,
        string[] memory _choices,
        uint256 offset
    ) public onlyAdmin() {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = name;
        ballots[nextBallotId].end = block.timestamp + offset;
        for (uint256 i = 0; i < _choices.length; i++) {
            ballots[nextBallotId].choices.push(Choice(i, _choices[i], 0));
        }
        nextBallotId++;
    }

    function vote(uint256 ballotId, uint256 choiceId) external {
        require(voters[msg.sender] == true, "only voters can vote");
        require(
            votes[msg.sender][ballotId] == false,
            "voter can only vote once for a ballot"
        );
        require(
            block.timestamp < ballots[ballotId].end,
            "can only vote until ballot end date"
        );
        votes[msg.sender][ballotId] = true;
        ballots[ballotId].choices[choiceId].votes++;
    }

    function results(uint256 ballotId) external view returns (Choice[] memory) {
        require(
            block.timestamp >= ballots[ballotId].end,
            "cannot see the ballot result before ballot end"
        );
        return ballots[ballotId].choices;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
}

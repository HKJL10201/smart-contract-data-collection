// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Voting {
    mapping(address => bool) public voters;
    struct Choice{
        uint id;
        string name;
        uint votes;
    }

    struct Ballot{
        uint id;
        string name;
        Choice[] choices;
        uint end;
    }

    mapping(uint => Ballot) public ballots;
    uint public nextBallotId;
    address public admin;
    mapping(address => mapping(uint => bool)) public votes;

    constructor() {
        admin = msg.sender;
    }

    function addVoter(address _voter) onlyAdmin() external{
        voters[_voter] = true;
    }

    function createBallot(string memory name, string[] memory choices, uint offset) onlyAdmin() public {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = name;
        ballots[nextBallotId].end = block.timestamp + offset;
        for (uint i = 0; i < choices.length; i++ ){
            ballots[nextBallotId].choices.push(Choice(i, choices[i], 0));
        }
        nextBallotId ++;
    }

    function vote(uint ballotId, uint choiceId) external {
        require (voters[msg.sender] == true, "Only voters can vote");
        require (votes[msg.sender][ballotId] ==false, "Voter can only vote once for a ballot");
        require( block.timestamp < ballots[ballotId].end , "Can only vote until ballot end date");
        votes[msg.sender][ballotId] = true;
        ballots[ballotId].choices[choiceId].votes++;
    }

    function getBallot(uint ballotId) view external returns(Ballot memory){
        return ballots[ballotId];
    }

    function results(uint ballotId) view external returns(Choice[] memory){
        require(block.timestamp >= ballots[ballotId].end, "Cannot see the ballot result before ballot end");
        return ballots[ballotId].choices;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin");
        _;
    }
}
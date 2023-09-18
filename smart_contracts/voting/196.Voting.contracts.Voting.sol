// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Voting {

  uint nextBallotId;
  address public owner;
  
  struct Choice {
    uint id;
    string[] names;
    uint votes;
  }

  struct Ballot {
    uint id;
    string name;
    Choice[] choices;
    uint end;
  }

  mapping(address => bool) public voters;
  mapping(uint => Ballot) public ballots;
  mapping(address => mapping(uint => bool)) public votes;

  constructor() {
    owner = msg.sender;
  }

  function addVoters(address[] memory _voters) external onlyAdmin() {
    for(uint i=0; i < _voters.length; i++){
      voters[_voters[i]] = true;
    }
  }

  function createBallot(string memory name, string[] memory choices, uint offset) external onlyAdmin(){
    ballots[nextBallotId].id = nextBallotId;
    ballots[nextBallotId].name = name;
    ballots[nextBallotId].end = block.timestamp+offset;

    for(uint i=0;i<choices.length;i++){
      ballots[nextBallotId].choices.push(Choice(i,choices,0));
    }
  }

  modifier onlyAdmin(){
    require(msg.sender == owner,'only admin can call');
    _;
  }

  function vote(uint ballotId, uint choiceId) external {
    require(voters[msg.sender] == true, 'you need to be a voter');
    require(votes[msg.sender][ballotId] == false, 'voter can vote only once');
    require(block.timestamp < ballots[ballotId].end, 'can vote only tilll end date');
    votes[msg.sender][ballotId] = true;
    ballots[ballotId].choices[choiceId].votes++;
  }

  function results(uint ballotId) external view returns(Choice[] memory){
    require(block.timestamp >= ballots[ballotId].end,'can not see results before end time');
    return ballots[ballotId].choices;
  }

}

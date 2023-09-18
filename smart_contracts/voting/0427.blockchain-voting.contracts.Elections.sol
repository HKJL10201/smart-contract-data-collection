// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Elections {
  struct Choice {
    uint id;
    string name;
    uint voteCount;
  }
  struct Ballot {
    uint id;
    string name;
    Choice[] choices;
    uint end;
  }
  mapping(address => bool) public voters;
  mapping(address => mapping(uint => bool)) public votes;
  mapping(uint => Ballot) public ballots;
  address public adminAddress;
  uint public nextBallot;

  constructor() {
    adminAddress = msg.sender;
  }

  function addVoters(address[] calldata voterAddresses) external onlyAdmin {
    for(uint i = 0; i < voterAddresses.length; i++) {
      voters[voterAddresses[i]] = true;
    }
  }

  function createBallot(string memory name, string[] memory allChoices, uint offset) external onlyAdmin {
    ballots[nextBallot].id = nextBallot;
    ballots[nextBallot].name = name;
    ballots[nextBallot].end = block.timestamp + offset;
    for(uint i = 0; i < allChoices.length; i++) {
      ballots[nextBallot].choices.push(Choice(i, allChoices[i],0));
    }
    nextBallot++;
  }

  function vote(uint ballotId, uint choiceId) external {
    require(voters[msg.sender] == true, 'address is not on voter list');
    require(votes[msg.sender][ballotId] == false, 'voter can vote only once');
    require(block.timestamp < ballots[ballotId].end , 'ballot voting has already ended');
    ballots[ballotId].choices[choiceId].voteCount++;
    votes[msg.sender][ballotId] = true;
  }

  function result(uint ballotId) view external returns(Choice[] memory) {
    require(block.timestamp >= ballots[ballotId].end, 'ballot is not over yet');
    return ballots[ballotId].choices;
  }

  function getBallotData(uint ballotId) view external returns(Ballot memory, Choice[] memory) {
    return (ballots[ballotId], ballots[ballotId].choices);
  }

  modifier onlyAdmin() {
    require(msg.sender == adminAddress, 'only admin action');
    _;
  }
}

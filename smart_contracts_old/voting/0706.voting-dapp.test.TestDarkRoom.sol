pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/DarkRoom.sol";

contract TestDarkRoom {

  function testInitialResults() public {
    DarkRoom darkRoom = DarkRoom(DeployedAddresses.DarkRoom());

    uint totalYes;
    uint totalNo;

    (totalYes, totalNo) = darkRoom.getResults();

    Assert.equal(totalYes, 0, "It should not be any vote for YES.");
    Assert.equal(totalNo, 0, "It should not be any vote for NO.");
  }

  function testVoterResultBeforeVoting() public {
    DarkRoom darkRoom = DarkRoom(DeployedAddresses.DarkRoom());

    address voter;
    bool vote;
    bool hasVoted;

    (voter, vote, hasVoted) = darkRoom.getVoter();

    Assert.equal(voter, this, "It should return the right voter address.");
    Assert.equal(hasVoted, false, "Voter should not been voted yet.");
  }

  function testResultsAfterVotingYES() public {
    DarkRoom darkRoom = DarkRoom(DeployedAddresses.DarkRoom());

    address voter;
    bool vote;
    bool hasVoted;

    uint totalYes;
    uint totalNo;

    darkRoom.vote(true);

    (totalYes, totalNo) = darkRoom.getResults();
    (voter, vote, hasVoted) = darkRoom.getVoter();

    Assert.equal(totalYes, 1, "It should be the right total for YES.");
    Assert.equal(totalNo, 0, "It should be the right total for NO.");
    Assert.equal(voter, this, "It should return the right voter address.");
    Assert.equal(vote, true, "Vote should right.");
    Assert.equal(hasVoted, true, "Voter should been already voted.");
  }

}

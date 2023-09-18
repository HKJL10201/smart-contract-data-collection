pragma solidity 0.5.16;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract VotingTest {

  function testVoteSatoshi() public {
    Voting voting = Voting(DeployedAddresses.Voting());

    Assert.equal(uint(voting.totalVotes("Satoshi")), uint(0), "Number of votes should equal 0");
    voting.vote("Satoshi");
    Assert.equal(uint(voting.totalVotes("Satoshi")), uint(1), "Number of votes should equal 1");
  }

  function testVoteJane() public {
    Voting voting = Voting(DeployedAddresses.Voting());

    Assert.equal(uint(voting.totalVotes("Jane")), uint(1), "It works correctly and throws exception");
  }
}
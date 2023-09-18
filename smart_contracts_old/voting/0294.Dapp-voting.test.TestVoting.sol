pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {
    Voting v = Voting(DeployedAddresses.Voting());
    function testVote() public {
    v.addCandidate("test","democracy",true);
    v.vote("0",0);
    uint expected = v.totalVotes(0);
    Assert.equal(1, expected, "OK");
  }
}
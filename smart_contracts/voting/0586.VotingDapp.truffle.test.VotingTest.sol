// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../contracts/Voting.sol";
// These files are dynamically created at test time
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract VotingTest {

  function testWriteValue() public {
    Voting voting = Voting(DeployedAddresses.Voting());

    Assert.equal(voting.read(), 0, "Contract should have 0 stored");
    voting.write(1);
    Assert.equal(voting.read(), 1, "Contract should have 1 stored");
    voting.write(2);
    Assert.equal(voting.read(), 2, "Contract should have 2 stored");
  }
}

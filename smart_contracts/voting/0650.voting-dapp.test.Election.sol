pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Election.sol";

contract TestElection {

  function testElection() public {
    Election election = Election(DeployedAddresses.Election());

    election.vote(1);
  }

}

pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Election.sol";

contract TestElection {
    Election election = Election(DeployedAddresses.Election());

    function testRegisterVotant() {
        Election.Votant memory votant = election.registerVotant("Joan", "12098623");
        Assert.equal(votant, election.getVotant());
    }
}

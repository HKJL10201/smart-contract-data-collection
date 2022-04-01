pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Vote.sol";

contract TestVote {

	Vote vote = Vote(DeployedAddresses.Vote());

	uint myVote = 1;
	
	uint returnedVote = vote.addPerson(myVote);

	function testUserCanVote() public {
  		Assert.equal(myVote, returnedVote, "The returned vote does not match the intended vote.");
	}


}
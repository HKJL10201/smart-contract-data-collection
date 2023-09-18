pragma solidity 0.5.8;

import "./ERC20Token.sol";

contract MinimalVotingWithEtherTransfer {
	address payable public owner;
	mapping(uint256 => uint256) public votes;
	
	constructor() public {
		owner = msg.sender;
	}
	
	function vote(uint256 _proposal) payable public {
		require(msg.value > 0);
		votes[_proposal] += msg.value;
	}
	
	function endVoting() public {
		require(msg.sender == owner);
		
		selfdestruct(owner);
	}
}

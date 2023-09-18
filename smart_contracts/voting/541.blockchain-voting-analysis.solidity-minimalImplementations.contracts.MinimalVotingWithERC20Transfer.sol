pragma solidity 0.5.8;

import "./ERC20Token.sol";

contract MinimalVotingWithERC20Transfer {
	address payable public owner;
	ERC20Token public token;
	mapping(uint256 => uint256) public votes;
	
	constructor(ERC20Token _token) public {
		owner = msg.sender;
		token = _token;
	}
	
	function vote(uint256 _number, uint256 _value) payable public {
		require(token.allowance(msg.sender, address(this)) >= _value);
		token.transfer(owner, _value);
		votes[_number] += _value;
	}
}

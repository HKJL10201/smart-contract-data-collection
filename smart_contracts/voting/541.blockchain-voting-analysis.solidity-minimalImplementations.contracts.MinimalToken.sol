pragma solidity ^0.5.8;

import "./ERC20Token.sol";

contract MinimalToken is ERC20Token {
	address holder;
	address allowed;

	constructor() public { holder = msg.sender; }

	function name() public view returns (string memory) { return ""; } // The empty token 8-)
	function symbol() public view returns (string memory) { return ""; }
	function decimals() public view returns (uint8) { return 0; }
	function totalSupply() public view returns (uint256) { return 1; }
	function balanceOf(address _owner) public view returns (uint256 balance) { return holder == _owner ? 1 : 0; }
	function transfer(address _to, uint256 _value) public returns (bool success) {
		if(msg.sender == allowed && _value == 1) {
			holder = _to;
			emit Transfer(msg.sender, _to, 1);
			success = true;
		} else {
			success = false;
		}
	}

	function approve(address _spender, uint256 _value) public returns (bool success) { 
		if(msg.sender == holder && _value == 1) {
			allowed = _spender;
			success = true;
			emit Approval(holder, allowed, 1);
		} else {
			success = false;
		}
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) { return _owner == holder && _spender == allowed ? 1 : 0; }
}
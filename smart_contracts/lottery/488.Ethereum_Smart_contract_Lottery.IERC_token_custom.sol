pragma solidity ^0.4.0;
contract IERC20_custom {
	//buy token for ether
	function buyTokens(uint256 number_of_tokens) payable public;
	//Get the total token sold
	function tokenSold() returns (uint256 tokenSold);
	//Get the ether earned
	function etherEarned() returns (uint256 etherEarned);
	//Get the account balance of another account with address _owner
	function balanceOf(address _owner) returns (uint256 balance);
	//Send _value amount of tokens to address _to
	function transfer(address _to, uint256 _value) private;
}

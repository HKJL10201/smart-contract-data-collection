pragma solidity ^0.4.0;

import "ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract MetaCoin {
	
	mapping (address => uint) balances;
	
	uint transamount;
	address transreceiver;
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	function fundaddr(address addr) {
		balances[addr] = 2000;
	}

	
	function sendCoin(address receiver, uint amount, address sender) returns(bool sufficient) {
		
		
		if (balances[sender] < amount) 
		return false;
		
		balances[sender] -= amount;
		balances[receiver] += amount;
		
		Transfer(sender, receiver, amount);
				
    	return true;
		
	}

	function set(address receiver, uint amount) {

		transreceiver = receiver;
		transamount = amount;
	}

	function getTransactionAmount() returns(uint) {
		return transamount;
	}

	function getTransactionReceiver() returns(address) {
		return transreceiver;
	}
	
	function getBalanceInEth(address addr) returns(uint) {
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) returns(uint) {
		return balances[addr];
	}
}
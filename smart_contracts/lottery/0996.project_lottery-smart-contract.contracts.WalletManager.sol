pragma solidity ^0.4.24;

import "./ConvertLib.sol";

contract WalletManager {

	mapping (address => uint256) balances;
	
	event Log(string log);
	constructor() public {
		emit Log("WalletManager constructor!!");
	}
	
	event LogFallback(address who, uint256 amt);

	function deposit() public payable returns(bool sufficient) {

		uint256 value     = msg.value;
		address sender   = msg.sender;
		
		require(sender != address(0));
		
		// 잔고 조회
		//require(value <= balances[sender]);
		
		// 기장
		balances[sender] += value;
		
		emit LogFallback(sender, value);
		
		return true;
	
	}

	function getBalanceInEth(address addr) public view returns(uint) {
		return ConvertLib.convert(getBalance(addr), 2);
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
	
//	function deposit() public payable {
//
//		uint256 value     = msg.value;
//		address sender   = msg.sender;
//		address receiver = owner;
//		
//		require(sender != address(0));
//		
//		// 잔고 조회
//		require(value <= balances[sender]);
//		
//		// 기장
//		balances[sender]   = balances[sender].sub(value);
//		balances[receiver] = balances[receiver].add(value);
//		
//		emit LogFallback(sender, value);
//	
//	}
	
}

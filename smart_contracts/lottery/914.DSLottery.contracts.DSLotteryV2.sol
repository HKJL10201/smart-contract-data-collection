pragma solidity 0.5.12;

import "./DSLottery.sol";

contract DSLotteryV2 is DSLottery{
	constructor() public{
		initialize(msg.sender);
	}

	function initialize(address owner) public {
		require(!_initialized);
		_owner = owner;
		_initialized = true;
	}
}

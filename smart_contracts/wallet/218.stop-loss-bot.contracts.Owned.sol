pragma solidity ^0.5.9;

// Adding only the ER-20 functions we need
interface DaiToken {
	function transfer(address dst, uint wad) external returns (bool);
	function balanceOf(address guy) external view returns (uint);
}

contract Owned {
	DaiToken daitoken;
	address owner;

	constructor() public {
			owner = msg.sender;
			daitoken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
	}

	modifier onlyOwner {
			require(msg.sender == owner, "Only the contract owner can call this function");
			_;
	}
}
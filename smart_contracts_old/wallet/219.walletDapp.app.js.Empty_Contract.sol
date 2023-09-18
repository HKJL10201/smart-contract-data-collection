pragma solidity ^0.4.21;

contract DIY {
    mapping (address => uint256) public balances;
    uint256 totalSupply = 21000000;
		address public contractCreator;
    event BalanceChanged(address indexed _address, uint256 _balance);

    constructor() public {
        balances[msg.sender] = totalSupply;        // Give the creator initially all the tokens
				contractCreator = msg.sender;
    }
}

pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

contract EthereumFinchainCourse is StandardToken, DetailedERC20 {

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) DetailedERC20(_name, _symbol, _decimals) public {
        _totalSupply = _totalSupply * (10 ** uint256(decimals));
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;
        emit Transfer(0x0, msg.sender, _totalSupply);
    }
}
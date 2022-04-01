pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
* @title BearToken is a basic ERC20 Token
*/
contract BearToken is StandardToken, Ownable{

    uint256 public _totalSupply;
    string public name;
    string public symbol;
    uint32 public decimals;
    address public _to;

    /**
    * @dev assign totalSupply to account creating this contract
    */
    constructor() public {
        symbol = "BEAR";
        name = "BearToken";
        decimals = 5;
        _totalSupply = 100000000000;
        // _to = "";

        owner = msg.sender;
        balances[msg.sender] = _totalSupply;

        emit Transfer(msg.sender, _to, _totalSupply);
    }
}
pragma solidity 0.4.15; 
import "./UnlimitedAllowanceToken.sol"; 
contract ZRXToken is UnlimitedAllowanceToken { 
    uint8 constant public decimals = 18;
    uint public totalSupply = 10**27; // 1 billion tokens, 18 decimal places
    string constant public name = "0x Protocol Token";
    string constant public symbol = "ZRX_Test"; 
    function ZRXToken() {
        balances[msg.sender] = totalSupply;
    }

    function approveProxy(address _account, address _spender, uint _value) returns (bool success) {
        allowed[_account][_spender] = _value;
        Approval(_account, _spender, _value);
        return true;
    }
}
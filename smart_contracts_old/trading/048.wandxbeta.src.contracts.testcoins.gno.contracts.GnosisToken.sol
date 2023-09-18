pragma solidity ^0.4.15;
import "./StandardToken.sol";
contract GnosisToken is StandardToken { 
    uint8 constant public decimals = 18;
    uint public totalSupply = 10**27; // 1 billion tokens, 18 decimal places
    string constant public name = "Gnosis";
    string constant public symbol = "GNO"; 
    function GnosisToken() {
        balances[msg.sender] = totalSupply;
    }
    function approveProxy(address _account, address _spender, uint _value) returns (bool success) {
        allowed[_account][_spender] = _value;
        Approval(_account, _spender, _value);
        return true;
    }

}
pragma solidity ^0.4.8;
import "./StandardToken.sol";

contract HumanStandardToken is StandardToken {  
    string public version = 'H0.1';  
    uint8 constant public decimals = 18;
    uint public totalSupply = 10**27; // 1 billion tokens, 18 decimal places
    string constant public name = "QTUM Token";
    string constant public symbol = "QTUM"; 

    function HumanStandardToken() {
        balances[msg.sender] = totalSupply;   
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function approveProxy(address _account, address _spender, uint _value) returns (bool success) {
        allowed[_account][_spender] = _value;
        Approval(_account, _spender, _value);
        return true;
    }
}
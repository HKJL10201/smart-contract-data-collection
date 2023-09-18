pragma solidity ^0.4.8;
import "./ERC20.sol";
import "./SafeMath.sol";
contract StandardToken is ERC20, SafeMath { 
    event Minted(address receiver, uint amount);
    mapping(address => uint) balances;  
    mapping (address => mapping (address => uint)) allowed;
    function isToken() public constant returns (bool weAre) {
        return true;
    } 
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            throw;
        }
        _;
    } 
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    } 
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        uint _allowance = allowed[_from][msg.sender]; 
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    } 
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    } 
    function approve(address _spender, uint _value) returns (bool success) {
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    } 
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    } 
}


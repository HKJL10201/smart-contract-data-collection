pragma solidity ^0.4.23;

contract EasyToken {

    uint256 public totalSupply;
    string public TokenName = "EasyToken";
    string public TokenSymbol = "EAS";

    // mapping
    mapping (address=> uint256) public balance;
    mapping (address=>mapping (address=>uint256)) public allowance;

    // constructor
    function EasyToken(uint256 _initialSupply) {
        balance[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    // event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // function

    function name() public view returns (string name) {
        return TokenName;
    }

    function symbol() public view returns (string symbol) {
        return TokenSymbol;
    }

    function totalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) view returns (uint256 ) {
        return balance[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balance[msg.sender] >= _value , " Not Enough amount");
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // allowance
        allowance[msg.sender][_spender] = _value;
        // event
        Approval(msg.sender,_spender,_value);
        // return

        return true;
    }

    function transferFrom(address _from , address _to , uint256 _amount) public returns (bool success){
        require(balance[_from] >= _amount, " Not Enough amount");
        require(allowance[_from][msg.sender] >= _amount, " Not allowed");

        // substract the amount
        balance[_from] -=_amount;
        // add the amount
        balance[_to] +=_amount;

        allowance[_from][msg.sender] -= _amount;

        // event
        Transfer( _from ,  _to ,  _amount);

        return true;
    }


}
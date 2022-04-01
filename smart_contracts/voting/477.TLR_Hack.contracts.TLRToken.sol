pragma solidity ^0.5.0;


contract TLRToken {
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals =18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    //this mapping keeps track which addresses have allowed whom to spend money from their wallets
    
    event Transfer(address indexed _from,address indexed _to,uint tokens);
    event Approval(address indexed _tokenOwner,address indexed _spender,uint tokens);
    event Burn(address indexed _from,uint _value);
    
    
    constructor() public {
  
        name="TLRToken";
        symbol="TLR";
  
    }
    
    function _transfer(address _from,address _to,uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
    }
    
    function transfer(address _to,uint _value) public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint _value) public returns(bool) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        return true;
    }
    
    function approve(address _spender,uint _value) public returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
        
    }
}



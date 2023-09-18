pragma solidity ^0.5.1;

import "./SafeMath.sol";


contract ERC20Interface {
  
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Interface {

    uint256 constant private MAX_UINT256 = 2 ** 256 - 1;
    uint256 _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    constructor(uint256 total) public{
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address add) public view returns (uint256) {
        return balances[add];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value && allowed[from][msg.sender] >= value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);
        if (allowed[from][msg.sender] < MAX_UINT256) {
            allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], value);
        }
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
//SPDX-License-Identifier: MIT
pragma solidity >=0.8 <0.9;
import './ERC20Interface.sol';

contract ERC20 is ERC20Interface{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) approval;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply, address _owner){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _initialSupply;
        balances[_owner] = _totalSupply;
    }

    function totalSupply() public override view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address _account) public override view returns(uint256){
        return balances[_account];
    }

    function transfer(address _to, uint256 _amount) public override returns(bool){
        require(balances[msg.sender] >= _amount, 'You do not have enough balance');
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool){
        require(approval[_from][msg.sender] >= _amount, 'You are not approved to withdraw from this account');
        require(balances[_from] >= _amount, 'Sender does not have the required balance');
        balances[_from] -= _amount;
        balances[_to] += _amount;
        approval[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _account, uint256 _amount) public override returns(bool){
        approval[msg.sender][_account] = _amount;
        emit Approve(msg.sender, _account, _amount);
        return true;
    }

    function allowance(address _from, address _to) public override view returns(uint256){
        return approval[_from][_to];
    }
}
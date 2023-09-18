//SPDX-License-Identifier: GPL 3.0
pragma solidity >=0.7.0 <0.9.0;

import './Ownable.sol';

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// API ->
contract myToken is IERC20, Ownable {
    string public override name = 'CygnusXrand';
    string public override symbol = 'XRD';
    uint8 public override decimals = 0;

    uint256 supply;
    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) _allowance;

    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return _allowance[_owner][_spender];
    }

    function approve(address _spender, uint256  _value) external override returns (bool success) {
        _allowance[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function totalSupply() public override view returns (uint256) {
        return supply;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value, 'Insufficient funds');
        balances[msg.sender] -= _value;
        require(balances[_to] + _value > balances[_to], 'Overflow');
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {
        require(_allowance[_from][msg.sender] >= _value, "Not allowed");
        require(balances[_from] >= _value, 'Insufficient funds');
        balances[_from] -= _value;
        require(balances[_to] + _value > balances[_to], 'Overflow');
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        _allowance[_from][msg.sender] -= _value;
        return true;
    }

    function mintAsOwner(uint256 _value) external isOwner {
        balances[msg.sender] += _value;
        supply += _value;
    } 

    function mint() external payable {
        require(msg.value >= 1 ether, 'Send more eth, please');
        balances[msg.sender] += 10 * msg.value;
        supply += 10 * msg.value;
    }

}

contract simpleSwap {
    function swap(address token1, uint256 amount1, address token2) external {
        // El swap se cobra de mi balance
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        // Luego el swap me da el dinero
        IERC20(token2).transfer(msg.sender, amount1);
    }
}
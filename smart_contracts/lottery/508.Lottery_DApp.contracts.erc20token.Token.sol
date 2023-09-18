// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyToken is IERC20 {
  address public owner;
  uint256 private _totalSupply;
  uint256 public tokenPrice = 0.01 ether;
  string private _name = "Simple";
  string private _symbol = "SIM"; 
  
  mapping(address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  constructor() {
    owner = msg.sender;
    _totalSupply = 100 * 10 ** 10;
    _balances[owner] = _totalSupply;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }
  
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  
  function allowance(address account, address spender) public view virtual override returns (uint256) {
    return _allowed[account][spender];
  }

  function buy(uint256 amount) public payable returns (bool) {
    require(_totalSupply >= uint(amount/tokenPrice));
    require(msg.value == amount * tokenPrice);
    _balances[msg.sender] = _balances[msg.sender] + amount;
    _totalSupply = _totalSupply - amount;
    return true;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[msg.sender] >= amount && amount > 0);
    _balances[msg.sender] = _balances[msg.sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    return true;
  }
  
  function approve(address spender, uint256 value) public virtual override returns (bool) {
    require(spender != address(0));
    require(_balances[msg.sender] >= value);
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);

    _balances[from] = _balances[from] - value;

    _balances[to] = _balances[to] + value;

    _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;

    emit Transfer(from, to, value);

    return true;
  }

  function withdraw(uint256 amount) public returns (bool) {
    require(amount <= _balances[msg.sender]);
    msg.sender.transfer(amount * tokenPrice);
    _totalSupply = _totalSupply + amount;
    return true;
  }

}
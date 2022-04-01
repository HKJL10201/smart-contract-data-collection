//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Ownable {
  string private _name = "ERC20Token";
  string private _symbol = "ERC20";
  uint8 private _decimals = 18;
  uint256 private _totalSupply = 50000 * 10 ** _decimals;

  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowances;

  constructor() ERC20(_name, _symbol) {

  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    _transfer(sender, recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer from the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if(sender != owner() && recipient != owner() ) {
      require(amount <= _totalSupply, "Transfer amount exceeds the totalSupply.");
    }
    _beforeTokenTransfer(sender, recipient, amount);
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transer amount exceeds balance");

    unchecked {
      _balances[sender] = senderBalance - amount;
    }

    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount); 
  }
  
  function _mint(address account, uint256 amount) internal override {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }
}

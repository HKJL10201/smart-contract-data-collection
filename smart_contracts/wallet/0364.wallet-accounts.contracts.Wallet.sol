// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol";
import "./Account.sol";

contract Wallet is AccessControl {
  bytes32 public constant ACCOUNT_ROLE = keccak256("ACCOUNT_ROLE");

  Account public modelAccount;
  mapping (bytes32 => address) public accounts; // + this could be bytes32 => Account

  event AccountCreated (address addr, uint256 index);

  constructor () {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ACCOUNT_ROLE, msg.sender);

    modelAccount = new Account();
    modelAccount.init(address(this));
  }

  function get (uint256 index) public view onlyRole(ACCOUNT_ROLE) returns (address addr, bool exists, bytes32 salt) {
    salt = bytes32(index);
    addr = Clones.predictDeterministicAddress(address(modelAccount), salt);
    exists = accounts[salt] != address(0);
  }

  function create (uint256 index) public onlyRole(ACCOUNT_ROLE) {
    (, bool exists, bytes32 salt) = get(index);
    require(!exists, "Account already exists");

    address addr = Clones.cloneDeterministic(address(modelAccount), salt);
    address newOwner = address(this);

    Account account = Account(payable(addr));
    account.init(newOwner);

    accounts[salt] = addr;
    emit AccountCreated(addr, index);
  }

  function transfer (uint256 index, address recipient, address assetAddress, uint256 amount) public onlyRole(ACCOUNT_ROLE) {
    (address addr, bool exists, ) = get(index);
    if (!exists) create(index);

    Account(payable(addr)).transfer(recipient, assetAddress, amount);
  }

  function swap (uint256 index, uint method, address router, uint amountIn, uint amountOutMin, address[] calldata path, address to) public onlyRole(ACCOUNT_ROLE) {
    (address addr, bool exists, ) = get(index);
    if (!exists) create(index);

    Account(payable(addr)).swap(method, router, amountIn, amountOutMin, path, to);
  }

  function transferBatch (uint256[] calldata index, address[] calldata recipient, address[] calldata assetAddress, uint256[] memory amount) external onlyRole(ACCOUNT_ROLE) {
    require(index.length >= 1);
    require(index.length == recipient.length && recipient.length == assetAddress.length && assetAddress.length == amount.length);

    for (uint256 i = 0; i < index.length; i++) {
      transfer(index[i], recipient[i], assetAddress[i], amount[i]);
    }
  }

  function swapBatch (uint256[] calldata index, uint[] memory method, address[] calldata router, uint[] memory amountIn, uint[] memory amountOutMin, address[][] calldata path, address[] calldata to) external onlyRole(ACCOUNT_ROLE) {
    require(index.length >= 1);
    require(index.length == method.length && method.length == router.length && router.length == amountIn.length && amountIn.length == amountOutMin.length && amountOutMin.length == path.length && path.length == to.length);

    for (uint256 i = 0; i < index.length; i++) {
      swap(index[i], method[i], router[i], amountIn[i], amountOutMin[i], path[i], to[i]);
    }
  }
}

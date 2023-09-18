// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _setOwner(_msgSender());
    }

    // @notice 函数, 返回当前合约地址的当前拥有者
    // @return _owner 合约地址所有者
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // @notice 修饰器, 用于判断仅限合约地址所有者调用
    // -- 如果被所有者以外的任何帐户调用，则抛出错误信息
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // @notice 函数, 放弃合约所有权, 使合约成为无主合约
    // -- 仅可由当前合约地址所有者调用
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    // @notice 函数, 移交合约所有权
    // -- 仅可由当前合约所有者调用
    // @param newOwner 该合约新的所有者
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    // @notice 函数, 设置当前合约所有者
    // -- private 表明该函数只能由合约内函数调用
    // @param newOwner 该合约新的所有者
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
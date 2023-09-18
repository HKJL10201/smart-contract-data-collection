// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

abstract contract Pausable is Context {
    
    // @notice 事件, 当用户(account)暂停时触发
    event Paused(address account);

    // @notice 事件, 当用户解除暂停时触发
    event Unpaused(address account);

    bool private _paused;

    // @notice 初始化暂停情况
    constructor() {
        _paused = false;
    }

    // @notice 函数, 如果合约暂停，则返回true，否则返回false。
    // @return _paused 当前合约的状态: true表示合约已暂停; false表示合约未暂停
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    // @notice 修饰器, 用于确保函数只有在"未暂停"时才可以调用
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    // @notice 修饰器, 用于确保函数只有在"暂停"时才可以调用
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    // @notice 函数, 将当前合约设置为暂停
    // -- 只有在当前"未暂停"情况下可以调用
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    // @notice 函数, 解除当前合约的暂停状态
    // -- 只有在当前"暂停"情况下可以调用
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
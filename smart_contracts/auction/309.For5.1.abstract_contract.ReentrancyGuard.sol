// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @dev 契约模块, 帮助防止函数的可重入调用
// 从'ReentrancyGuard'继承, 将引入nonReentrant修饰符, 它可以应用到函数中以确保没有嵌套(可重入)调用它们.
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    // @notice 修饰器, 防止函数重复调用
    modifier nonReentrant() {
        // 在第一次调用nonReentrant时, _notEntered 将为true(表明从未调用过)
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // 在此之后对nonReentrant的任何调用都将失败, 因为此时已经将状态值设置为"_ENTERED", 表示该函数调用过此修饰符
        _status = _ENTERED;
        _;

        // 通过再次存储原始值, 触发退款接触调用状态(即表明该修饰符修饰的函数已运行完毕, 再未运行完毕的过程中, 该函数不可重复调用)
        _status = _NOT_ENTERED;
    }
}
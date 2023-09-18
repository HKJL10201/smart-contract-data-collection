// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

interface IUniswap3 {
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external returns (int256 amount0, int256 amount1);
    function token0() external returns (IERC20);
    function token1() external returns (IERC20);
}
interface IERC20 {
    function transferFrom(address from, address to, uint256 tokens) external;
}

contract Uniswap3Trader {
    address immutable OWNER;
    IUniswap3 immutable POOL;
    IERC20 immutable TOKEN0;
    IERC20 immutable TOKEN1;

    constructor(IUniswap3 pool) {
        OWNER = msg.sender;
        POOL = pool;
        TOKEN0 = pool.token0();
        TOKEN1 = pool.token1();
    }
    
    //TOKEN0 => TOKEN1
    function buyExactIn(uint256 amountIn, uint256 minAmountOut, uint256 deadline) external payable {
        require(block.timestamp <= deadline, "expired");
        require(msg.sender == OWNER);

        (, int256 amountOut) = POOL.swap(msg.sender, true, int256(amountIn), 4295128740, bytes(''));
        require(uint256(-amountOut) >= minAmountOut, "!amount");

        if(msg.value > 0) payable(block.coinbase).transfer(msg.value);
    }

    //TOKEN0 => TOKEN1
    function buyExactOut(uint256 amountOut, uint256 maxAmountIn, uint256 deadline) external payable {
        require(block.timestamp <= deadline, "expired");
        require(msg.sender == OWNER);

        (int256 amountIn,) = POOL.swap(msg.sender, true, -int256(amountOut), 4295128740, bytes(''));
        require(uint256(amountIn) <= maxAmountIn, "!amount");

        if(msg.value > 0) payable(block.coinbase).transfer(msg.value);
    }

    //TOKEN1 => TOKEN0
    function sellExactIn(uint256 amountIn, uint256 minAmountOut, uint256 deadline) external payable {
        require(block.timestamp <= deadline, "expired");
        require(msg.sender == OWNER);

        (int256 amountOut,) = POOL.swap(msg.sender, false, int256(amountIn), 1461446703485210103287273052203988822378723970341, bytes(''));
        require(uint256(-amountOut) >= minAmountOut, "!amount");

        if(msg.value > 0) payable(block.coinbase).transfer(msg.value);
    }

    //TOKEN1 => TOKEN0
    function sellExactOut(uint256 amountOut, uint256 maxAmountIn, uint256 deadline) external payable {
        require(block.timestamp <= deadline, "expired");
        require(msg.sender == OWNER);

        (,int256 amountIn) = POOL.swap(msg.sender, false, -int256(amountOut), 1461446703485210103287273052203988822378723970341, bytes(''));
        require(uint256(amountIn) <= maxAmountIn, "!amount");

        if(msg.value > 0) payable(block.coinbase).transfer(msg.value);
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata /*data*/) external {
        //if(amount0Delta <= 0) require(amount1Delta > 0);
        require(msg.sender == address(POOL), "!pool");

        if(amount0Delta > 0) {
            TOKEN0.transferFrom(tx.origin, msg.sender, uint256(amount0Delta));
        }
        else {
            TOKEN1.transferFrom(tx.origin, msg.sender, uint256(amount1Delta));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract Adapter is ReentrancyGuard {
    address private factory;
    address private router;

    mapping(address => mapping(address => uint256)) private _TokenBalances;
    mapping(address => uint256) private _balances;

    event LiquidityAdded(
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity,
        address indexed pair,
        address to
    );
    event LiquidityETHAdded(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity,
        address to
    );
    event LiquidityRemoved(
        uint256 amountA,
        uint256 amountB,
        address pair,
        address to
    );
    event TokensSwapped(uint256[] amounts, address pair);

    constructor(address _factory, address _router) {
        factory = _factory;
        router = _router;
    }

    receive() external payable {
        _balances[msg.sender] += msg.value;
    }

    function getPair(address tokenA, address tokenB)
        public
        view
        returns (address)
    {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        address pair = IUniswapV2Factory(factory).getPair(token0, token1);
        return pair;
    }

    function getQuote(
        address tokenA,
        address tokenB,
        uint256 amountA
    ) external view returns (uint256) {
        require(tokenA != tokenB, "IDENTICAL ADDRESSES");

        address pair = getPair(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        (uint256 reserveA, uint256 reserveB) = IUniswapV2Pair(pair).token0() ==
            tokenA
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 amountB = IUniswapV2Router02(router).quote(
            amountA,
            reserveA,
            reserveB
        );
        return amountB;
    }

    /*
    TokenA (approved by user to Adapter) -> Adapter (calls Router2, which transferFrom to Pair) -> Pair
    */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        external
        virtual
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity,
            address pair
        )
    {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        _TokenBalances[msg.sender][tokenA] += amountADesired;
        _TokenBalances[msg.sender][tokenB] += amountBDesired;

        IERC20(tokenA).approve(router, amountADesired);
        IERC20(tokenB).approve(router, amountBDesired);

        uint256 deadline = block.timestamp + 10 minutes;
        (amountA, amountB, liquidity) = IUniswapV2Router02(router).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to, // lp tokens receiver
            deadline
        );

        pair = getPair(tokenA, tokenB);
        _TokenBalances[msg.sender][tokenA] -= amountA;
        _TokenBalances[msg.sender][tokenB] -= amountB;

        emit LiquidityAdded(amountA, amountB, liquidity, pair, to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    )
        external
        payable
        virtual
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        _balances[msg.sender] += msg.value;
        IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        IERC20(token).approve(router, amountTokenDesired);
        _TokenBalances[msg.sender][token] += amountTokenDesired;

        uint256 deadline = block.timestamp + 10 minutes;
        bytes memory callData = abi.encodeWithSignature(
            "addLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );

        (bool success, bytes memory data) = router.call{value: msg.value}(
            callData
        );
        (amountToken, amountETH, liquidity) = abi.decode(
            data,
            (uint256, uint256, uint256)
        );
        _TokenBalances[msg.sender][token] -= amountToken;
        _balances[msg.sender] -= amountETH;

        emit LiquidityETHAdded(amountToken, amountETH, liquidity, to);
    }

    /*
    TokenA -> User
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public virtual returns (uint256 amountA, uint256 amountB) {
        address pair = getPair(tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(router, liquidity);

        uint256 deadline = block.timestamp + 10 minutes;
        (amountA, amountB) = IUniswapV2Router02(router).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        emit LiquidityRemoved(amountA, amountB, pair, to);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) public virtual returns (uint256 amountToken, uint256 amountETH) {
        address pair = getPair(token, IUniswapV2Router02(router).WETH());
        IUniswapV2Pair(pair).transferFrom(msg.sender, address(this), liquidity);
        IUniswapV2Pair(pair).approve(router, liquidity);

        uint256 deadline = block.timestamp + 10 minutes;
        (amountToken, amountETH) = IUniswapV2Router02(router)
            .removeLiquidityETH(
                token,
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
        emit LiquidityRemoved(amountToken, amountETH, pair, to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external virtual returns (uint256[] memory amounts) {
        uint256 deadline = block.timestamp + 10 minutes;

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(router, amountIn);

        amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );

        emit TokensSwapped(amounts, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external virtual returns (uint256[] memory amounts) {
        uint256 deadline = block.timestamp + 10 minutes;

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(path[0]).approve(router, amountInMax);
        amounts = IUniswapV2Router02(router).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        emit TokensSwapped(amounts, to);
    }

    function withdraw(address token) external nonReentrant {
        uint256 withdrawalAmount = _TokenBalances[msg.sender][token];
        _TokenBalances[msg.sender][token] = 0;
        IERC20(token).transfer(msg.sender, withdrawalAmount);
    }

    function withdrawETH() external nonReentrant {
        uint256 withdrawalAmount = _balances[msg.sender];
        _balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: withdrawalAmount}("");
        require(success, "Transanction: withrawal failed");
    }

    function getBalanceETH() external view returns (uint256) {
        return _balances[msg.sender];
    }

    function getBalance(address token) external view returns (uint256) {
        return _TokenBalances[msg.sender][token];
    }
}

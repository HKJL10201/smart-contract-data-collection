//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./UniswapInterface.sol";
import "./Adapter.sol";
import "./Sweepable.sol";

interface SolidlyRouter {
    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface SolidlyFixedRouter {
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint);
}

contract SolidlyAdapter is Adapter, Sweepable {
    address public override immutable router;
    address public immutable fixedRouter;

    constructor(address _router, address _fixedRouter) {
        router = _router;
        fixedRouter = _fixedRouter;
    }

    function swap(IERC20 from, IERC20 to, uint amount, uint minOut, address destination) public override {
        from.approve(router, amount);

        SolidlyRouter(router).swapExactTokensForTokensSimple(
            amount,
            minOut,
            address(from),
            address(to),
            true,
            destination,
            block.timestamp
        );
    }

    function getRatio(IERC20 from, IERC20 to, uint amount) public override view returns (uint) {
        SolidlyFixedRouter _fixedRouter = SolidlyFixedRouter(fixedRouter);

        uint amountOut = _fixedRouter.getAmountOut(
            amount,
            address(from),
            address(to),
            true
        );

        return ((1 ether) * 1000) / amountOut;
    }
}
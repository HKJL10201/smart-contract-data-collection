//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Adapter.sol";
import "./UniswapInterface.sol";
import "./Sweepable.sol";

contract UniswapAdapter is Adapter, Sweepable {
    address public override immutable router;

    constructor(address _router) {
        router = _router;
    }

    function swap(IERC20 from, IERC20 to, uint amount, uint minOut, address destination) public override {
        from.approve(router, amount);

        address[] memory route = new address[](2);
        route[0] = address(from);
        route[1] = address(to);

        UniswapRouter(router).swapExactTokensForTokens(
            amount,
            minOut,
            route,
            address(destination),
            block.timestamp
        );
    }

    function getRatio(IERC20 from, IERC20 to, uint amount) public override view returns (uint) {
        address[] memory route = new address[](2);
        route[0] = address(from);
        route[1] = address(to);
        uint[] memory amountsOut = UniswapRouter(router).getAmountsOut(amount, route);

        return (amountsOut[0] * 1000) / (amountsOut[1]);
    }
}
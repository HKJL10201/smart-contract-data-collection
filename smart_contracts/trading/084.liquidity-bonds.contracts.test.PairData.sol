// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces
import "./Ubeswap/interfaces/IUniswapV2Pair.sol";

contract PairData {
    constructor() {}

    function getTotalSupply(address _pair) external view returns (uint256) {
        return IUniswapV2Pair(_pair).totalSupply();
    }

    function getBalanceOf(address _pair, address _user) external view returns (uint256) {
        return IUniswapV2Pair(_pair).balanceOf(_user);
    }

    function getReserves(address _pair) external view returns (uint112, uint112, uint32) {
        return IUniswapV2Pair(_pair).getReserves();
    }

    function getPrice0(address _pair) external view returns (uint256) {
        return IUniswapV2Pair(_pair).price0CumulativeLast();
    }

    function getPrice1(address _pair) external view returns (uint256) {
        return IUniswapV2Pair(_pair).price1CumulativeLast();
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function token0(address _pair) external view returns (address) {
        return IUniswapV2Pair(_pair).token0();
    }
}
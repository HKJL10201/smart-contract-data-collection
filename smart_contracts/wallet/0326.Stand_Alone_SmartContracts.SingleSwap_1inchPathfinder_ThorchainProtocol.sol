//SINGLE SWAP W/1INHC PATHFINDER + THORCHAIN PROTOCOL

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IOneInchPathfinder {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

interface IThorChain {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution
    ) external payable;
}

abstract contract SingleSwap is IERC20 {
    using SafeMath for uint256;

    IOneInchPathfinder public oneInchPathfinder;
    IThorChain public thorChain;

    constructor(address _oneInchPathfinder, address _thorChain) {
        oneInchPathfinder = IOneInchPathfinder(_oneInchPathfinder);
        thorChain = IThorChain(_thorChain);
    }

    function executeSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 minReturn
    ) external {
        // Get the best price from 1inch PathFinder
        (uint256 expectedReturn, uint256[] memory distribution) = oneInchPathfinder.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );

        require(expectedReturn >= minReturn, "Return amount is too low");

        // Execute the cross-chain swap using ThorChain
        thorChain.swap(fromToken, toToken, amount, minReturn, distribution);
    }
}

/*
This Solidity smart contract integrates 1inch PathFinder and ThorChain to execute a single swap with the best price
outputted by the 1inch protocol. It imports OpenZeppelin's IERC20 and SafeMath contracts.

The contract has an interface for the 1inch PathFinder and ThorChain, which allows it to interact with these
protocols. In the constructor, the addresses of the 1inch PathFinder and ThorChain are set.

The `executeSwap` function takes the tokens to be swapped, the amount, parts, flags, and a minimum return as input.
It first calls the 1inch PathFinder's `getExpectedReturn` function to get the best price and distribution. Then, it checks if the expected return is greater than or equal to the minimum return. If it is, it proceeds to execute the cross-chain swap using ThorChain's `swap` function.

Please note that the contract addresses for 1inch PathFinder and ThorChain should be set to the correct addresses on the Ethereum, BSC, Polygon, and WAX networks.
*/

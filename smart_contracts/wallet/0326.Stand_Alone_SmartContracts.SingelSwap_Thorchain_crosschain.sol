//SINGLE SWAP W/THORCHAIN CROSSCHAIN SWAP

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

// This contract integrates ThorChain cross chain swap protocol to execute
// the cross chain swaps for tokens on Ethereum, BSC, Polygon and WAX networks.
contract ThorChainSwap {
    using SafeMath for uint256;

    // Mapping to store the supported networks and their corresponding router addresses
    mapping(bytes32 => address) public routers;

    // Event to log the successful swap
    event SwapExecuted(
        address indexed sender,
        address indexed recipient,
        uint256 amountIn,
        uint256 amountOut,
        bytes32 network
    );

    // Modifier to check if the network is supported
    modifier onlySupportedNetwork(bytes32 network) {
        require(routers[network] != address(0), "Network not supported");
        _;
    }

    constructor() {
        // Initialize router addresses for Ethereum, BSC, Polygon and WAX networks
        routers["ETH"] = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap: Ethereum router address
        routers["BSC"] = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PancakeSwap: BSC router address
        routers["POLYGON"] = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // QuickSwap: Polygon router address
    }

    // Function to execute the cross chain swap
    function executeSwap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        address recipient,
        bytes32 network
    ) external onlySupportedNetwork(network) {
        // Transfer the input tokens from the sender to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend the input tokens
        IERC20(tokenIn).approve(routers[network], amountIn);

        // Call the swap function of the ThorChain router
        // Replace with the actual swap function signature and parameters of the ThorChain router
        (bool success, ) = routers[network].call(
            abi.encodeWithSignature(
                "swap(address,uint256,address,uint256,address)",
                tokenIn,
                amountIn,
                tokenOut,
                amountOut,
                recipient
            )
        );
        require(success, "Swap execution failed");

        // Emit the SwapExecuted event
        emit SwapExecuted(msg.sender, recipient, amountIn, amountOut, network);
    }

    // Function to add or update a supported network and its corresponding router address
    function setRouterAddress(bytes32 network, address router) external {
        routers[network] = router;
    }
}

/*
This smart contract integrates the ThorChain cross-chain swap protocol to execute swaps for tokens on Ethereum, BSC, Polygon, and WAX networks.
It uses OpenZeppelin's IERC20 and SafeMath libraries to handle token transfers and arithmetic operations safely.

Please note that this contract assumes the ThorChain router addresses for each network are known.
Replace the router addresses in the constructor with the actual addresses for the respective networks.
Also, replace the swap function signature and parameters in the `executeSwap` function with the actual ThorChain router's swap function.

Make sure to thoroughly test and audit the contract before deploying it to the mainnet.
*/

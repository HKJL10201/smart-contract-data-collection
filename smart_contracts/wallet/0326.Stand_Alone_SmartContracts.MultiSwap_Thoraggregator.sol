// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "../.env";

// Interface for the ThorChain Router contract
interface IThorChainRouter {
    function swap(
        address[] calldata _path,
        uint256 _srcAmount,
        uint256 _minDstAmount,
        address _recipient
    ) external returns (uint256);
}

// ThorChain Aggregator contract for multi-hop swaps
contract MultiSwap is ReentrancyGuard {
    // address public ETH_ADDRESS = process.env.ETH_ADDRESS;
    // address public BSC_ADDRESS = process.env.BSC_ADDRESS;
    // address public POLYGON_ADDRESS = process.env.BSC_ADDRESS;
    // address public THORCHAIN_ADDRESS = process.env.BSC_ADDRESS;
    // IThorChainRouter public thorChainRouter = process.env.THORCHAIN_ROUTER;

    address public ETH_ADDRESS;
    address public BSC_ADDRESS;
    address public POLYGON_ADDRESS;
    address public THORCHAIN_ADDRESS;
    IThorChainRouter public thorChainRouter;

    // Event for logging swaps
    event Swap(
        address indexed srcToken,
        address indexed dstToken,
        uint256 srcAmount,
        uint256 dstAmount,
        address indexed recipient
    );

    // Constructor to initialize the contract with the router address and supported token addresses
    constructor(
        address _thorChainRouter,
        address _ethAddress,
        address _bscAddress,
        address _polygonAddress,
        address _thorChainAddress
    ) {
        require(_thorChainRouter != address(0), "Router address cannot be zero");
        thorChainRouter = IThorChainRouter(_thorChainRouter);

        require(_ethAddress != address(0), "ETH address cannot be zero");
        require(_bscAddress != address(0), "BSC address cannot be zero");
        require(_polygonAddress != address(0), "Polygon address cannot be zero");
        require(_thorChainAddress != address(0), "ThorChain address cannot be zero");

        ETH_ADDRESS = _ethAddress;
        BSC_ADDRESS = _bscAddress;
        POLYGON_ADDRESS = _polygonAddress;
        THORCHAIN_ADDRESS = _thorChainAddress;
    }

    // Function to perform multi-hop swaps
    function swapTokens(
        address[] calldata _path,
        uint256 _srcAmount,
        uint256 _minDstAmount,
        address _recipient
    ) external nonReentrant {
        require(_path.length >= 2, "Path must have at least two tokens");
        address _srcToken = _path[0];
        address _dstToken = _path[_path.length - 1];

        // Validate source and destination tokens
        for (uint256 i = 0; i < _path.length; i++) {
            require(
                _path[i] == ETH_ADDRESS ||
                    _path[i] == BSC_ADDRESS ||
                    _path[i] == POLYGON_ADDRESS ||
                    _path[i] == THORCHAIN_ADDRESS,
                "Unsupported token in path"
            );
        }
        require(_recipient != address(0), "Recipient address cannot be zero");

        // Transfer tokens from sender to the contract and approve the router to spend them
        if (_srcToken != ETH_ADDRESS) {
            IERC20(_srcToken).transferFrom(msg.sender, address(this), _srcAmount);
            IERC20(_srcToken).approve(address(thorChainRouter), _srcAmount);
        }

        // Perform the multi-hop swap
        uint256 dstAmount = thorChainRouter.swap(_path, _srcAmount, _minDstAmount, _recipient);
        require(dstAmount >= _minDstAmount, "Insufficient output amount");
        emit Swap(_srcToken, _dstToken, _srcAmount, dstAmount, _recipient);
    }
}

/*
This Solidity smart contract is designed to support multi-hop swaps using the ThorChain Router. The contract imports the ReentrancyGuard and IERC20 contracts from OpenZeppelin for added security and token management.

The `IThorChainRouter` interface defines the `swap` function, which accepts an array of addresses as the path and processes the swaps accordingly.

The `ThorChainAggregator` contract inherits from `ReentrancyGuard` to prevent reentrancy attacks. It stores the addresses of supported tokens (ETH, BSC, Polygon, and ThorChain) and the ThorChain Router.

The `swapTokens` function accepts a path of token addresses, source amount, minimum destination amount, and recipient address. It validates the tokens in the path, transfers the source tokens from the sender to the contract, and approves the router to spend them. Then, it performs the multi-hop swap using the ThorChain Router's `swap` function and emits a `Swap` event with the relevant details.
*/

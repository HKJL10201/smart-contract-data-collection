// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./AtomicSwap.sol";
import "./interfaces/I1inchRouter.sol";
import "./interfaces/I1InchAggregator.sol";

contract SingleSwap is ReentrancyGuard {
    using SafeMath for uint256;

    // Oracle price feed interface
    AggregatorV3Interface internal priceFeed;

    // AtomicSwap contract instance
    AtomicSwap public atomicSwapInstance;

    // 1inch router contract instance
    I1InchRouter public oneInchRouter;

    // 1inch aggregator contract instances for each network
    I1InchAggregator public ethAggregator;
    I1InchAggregator public bscAggregator;
    I1InchAggregator public polygonAggregator;
    I1InchAggregator public waxAggregator;

    constructor(
        address _atomicSwapAddress,
        address _priceFeedAddress,
        address _oneInchRouterAddress,
        address _ethAggregatorAddress,
        address _bscAggregatorAddress,
        address _polygonAggregatorAddress,
        address _waxAggregatorAddress
    ) {
        atomicSwapInstance = AtomicSwap(_atomicSwapAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        oneInchRouter = I1InchRouter(_oneInchRouterAddress);
        ethAggregator = I1InchAggregator(_ethAggregatorAddress);
        bscAggregator = I1InchAggregator(_bscAggregatorAddress);
        polygonAggregator = I1InchAggregator(_polygonAggregatorAddress);
        waxAggregator = I1InchAggregator(_waxAggregatorAddress);
    }

    // Get the latest price from the oracle
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    // Perform a single swap using the AtomicSwap contract and the 1inch router
    function performSingleSwap(
        address _participant,
        address _inputToken,
        address _outputToken,
        uint256 _value,
        bytes32 _secretHash,
        uint256 _timelock
    ) external nonReentrant {
        uint256 requiredAmount = getRequiredAmount(_value);
        atomicSwapInstance.initiateSwap(
            _participant,
            _inputToken,
            requiredAmount,
            _secretHash,
            _timelock
        );

        address[] memory path = new address[](2);
        path[0] = _inputToken;
        path[1] = _outputToken;

        uint256 deadline = block.timestamp + 300; // 5 minutes from now

        IERC20(_inputToken).approve(address(oneInchRouter), requiredAmount);

        uint256 minReturn = oneInchRouter.getAmountsOut(requiredAmount, path)[1];

        // Update the function call to match the interface
        oneInchRouter.Swap(
            _inputToken,
            _outputToken,
            requiredAmount,
            minReturn,
            path,
            msg.sender, // Beneficiary receiving the swapped tokens
            deadline
        );
    }

    // Calculate the required amount based on the oracle price feed
    function getRequiredAmount(uint256 _value) public view returns (uint256) {
        int256 latestPrice = getLatestPrice();
        require(latestPrice > 0, "Invalid price feed");
        uint256 requiredAmount = _value.mul(uint256(latestPrice));
        return requiredAmount;
    }

    // Fetch and compare quotes from the 1inch aggregator for each network
    function fetchAndCompareQuotes(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) public view returns (uint256[] memory) {
        uint256[] memory quotes = new uint256[](4);
        quotes[0] = ethAggregator.getExpectedReturn(_fromToken, _toToken, _amount);
        quotes[1] = bscAggregator.getExpectedReturn(_fromToken, _toToken, _amount);
        quotes[2] = polygonAggregator.getExpectedReturn(_fromToken, _toToken, _amount);
        quotes[3] = waxAggregator.getExpectedReturn(_fromToken, _toToken, _amount);
        return quotes;
    }

    // Fetch and return the best quotes for each token on each network
    function getBestQuotes(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) public view returns (uint256, uint256) {
        uint256[] memory quotes = fetchAndCompareQuotes(_fromToken, _toToken, _amount);
        uint256 bestQuote = quotes[0];
        uint256 bestNetwork = 0;

        for (uint256 i = 1; i < quotes.length; i++) {
            if (quotes[i] > bestQuote) {
                bestQuote = quotes[i];
                bestNetwork = i;
            }
        }

        return (bestQuote, bestNetwork);
    }
}

/*
This updated `SingleSwap.sol` contract integrates the 1inch aggregator pathfinder as requested.

It imports additional interfaces for the 1inch router and aggregator, creates instances of the 1inch aggregator
for each network (Ethereum, BSC, Polygon, and WAX), and adds functions to fetch and compare quotes from the 
1inch aggregator for each network.

The `performSingleSwap` function is also updated to use the 1inch router to execute the trades. 
The `fetchAndCompareQuotes` function fetches and compares quotes from the 1inch aggregator for each network, 
and the `getBestQuotes` function fetches and returns the best quotes for each token on each network.
*/

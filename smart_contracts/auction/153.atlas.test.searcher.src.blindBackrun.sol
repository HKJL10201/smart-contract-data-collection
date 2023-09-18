pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract BlindBackrun is Ownable {
    using SafeMath for uint256;

    struct PairReserves {
        uint256 reserve0;
        uint256 reserve1;
        uint256 price;
        bool isWETHZero;
    }

    address private constant _WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /*
    address public immutable WETH_ADDRESS;

    constructor(address _wethAddress) {
        WETH_ADDRESS = _wethAddress;
    }
    */
    constructor() {}

    /// @notice Executes an arbitrage transaction between two Uniswap V2 pairs.
    /// @notice Pair addresses need to be computed off-chain.
    /// @dev Only the contract owner can call this function.
    /// @param firstPairAddress Address of the first Uniswap V2 pair.
    /// @param secondPairAddress Address of the second Uniswap V2 pair.
    function executeArbitrage(
        address firstPairAddress,
        address secondPairAddress //,
            //uint percentageToPayToCoinbase
    ) external {
        //onlyOwner {
        require(msg.sender == address(this), "INVALID CALLER"); // Atlas meta-tx integration

        uint256 balanceBefore = IERC20(_WETH_ADDRESS).balanceOf(address(this));
        IUniswapV2Pair firstPair = IUniswapV2Pair(firstPairAddress);
        IUniswapV2Pair secondPair = IUniswapV2Pair(secondPairAddress);

        // console.log("bb balanceBefore",balanceBefore);

        PairReserves memory firstPairData = getPairData(firstPair);
        PairReserves memory secondPairData = getPairData(secondPair);

        uint256 amountIn = getAmountIn(firstPairData, secondPairData);
        IERC20(_WETH_ADDRESS).transfer(firstPairAddress, amountIn);

        uint256 firstPairAmountOut;
        uint256 finalAmountOut;

        if (firstPairData.isWETHZero == true) {
            firstPairAmountOut = getAmountOut(amountIn, firstPairData.reserve0, firstPairData.reserve1);
            finalAmountOut = getAmountOut(firstPairAmountOut, secondPairData.reserve1, secondPairData.reserve0);

            firstPair.swap(0, firstPairAmountOut, secondPairAddress, "");
            secondPair.swap(finalAmountOut, 0, address(this), "");
        } else {
            firstPairAmountOut = getAmountOut(amountIn, firstPairData.reserve1, firstPairData.reserve0);
            finalAmountOut = getAmountOut(firstPairAmountOut, secondPairData.reserve0, secondPairData.reserve1);

            firstPair.swap(firstPairAmountOut, 0, secondPairAddress, "");
            secondPair.swap(0, finalAmountOut, address(this), "");
        }

        uint256 balanceAfter = IERC20(_WETH_ADDRESS).balanceOf(address(this));

        require(balanceAfter > balanceBefore, "Arbitrage failed");
        // uint profit = balanceAfter.sub(balanceBefore);
        // uint profitToCoinbase = profit.mul(percentageToPayToCoinbase).div(100);
        // IWETH(_WETH_ADDRESS).withdraw(profitToCoinbase);
        // block.coinbase.transfer(profitToCoinbase);
    }

    /// @notice Calculates the required input amount for the arbitrage transaction.
    /// @param firstPairData Struct containing data about the first Uniswap V2 pair.
    /// @param secondPairData Struct containing data about the second Uniswap V2 pair.
    /// @return amountIn, the optimal amount to trade to arbitrage two v2 pairs.
    function getAmountIn(PairReserves memory firstPairData, PairReserves memory secondPairData)
        internal
        pure
        returns (uint256)
    {
        uint256 uniswappyFee = 997;
        uint256 numerator =
            sqrt(uniswappyFee.mul(uniswappyFee).mul(firstPairData.price).mul(secondPairData.price)).sub(1e18);
        uint256 denominatorPart1 = (uniswappyFee.mul(1e18)).div(firstPairData.reserve1);
        uint256 denominatorPart2 =
            (uniswappyFee.mul(uniswappyFee).mul(firstPairData.price)).div(secondPairData.reserve1);
        uint256 denominator = denominatorPart1.add(denominatorPart2);
        uint256 amountIn = numerator.div(denominator);
        return amountIn;
    }

    /// @notice Retrieves price and reserve data for a given Uniswap V2 pair. Also checks which token is WETH.
    /// @param pair The Uniswap V2 pair to retrieve data for.
    /// @return A PairReserves struct containing price and reserve data for the given pair.
    function getPairData(IUniswapV2Pair pair) private view returns (PairReserves memory) {
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 price;

        bool isWETHZero = false;
        if (pair.token0() == _WETH_ADDRESS) {
            price = reserve1.mul(1e18).div(reserve0);
            isWETHZero = true;
        } else {
            price = reserve0.mul(1e18).div(reserve1);
        }

        return PairReserves(reserve0, reserve1, price, isWETHZero);
    }

    /// @notice Calculates the square root of a given number.
    /// @param x: The number to calculate the square root of.
    /// @return y: The square root of the given number.
    function sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = x.add(1).div(2);
        uint256 y = x;
        while (z < y) {
            y = z;
            z = ((x.div(z)).add(z)).div(2);
        }
        return y;
    }

    /// @notice Calculates the output amount for a given input amount and reserves.
    /// @param amountIn The input amount.
    /// @param reserveIn The reserve of the input token.
    /// @param reserveOut The reserve of the output token.
    /// @return amountOut The output amount.
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
        return amountOut;
    }

    /// @notice Transfers all WETH held by the contract to the contract owner.
    /// @dev Only the contract owner can call this function.
    function withdrawWETHToOwner() external onlyOwner {
        uint256 balance = IERC20(_WETH_ADDRESS).balanceOf(address(this));
        IERC20(_WETH_ADDRESS).transfer(msg.sender, balance);
    }

    /// @notice Transfers all ETH held by the contract to the contract owner.
    /// @dev Only the contract owner can call this function.
    function withdrawETHToOwner() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Executes a call to another contract with the provided data and value.
    /// @dev Only the contract owner can call this function.
    /// @dev Reverted calls will result in a revert.
    /// @param _to The address of the contract to call.
    /// @param _value The amount of Ether to send with the call.
    /// @param _data The calldata to send with the call.
    function call(address payable _to, uint256 _value, bytes memory _data) external onlyOwner {
        (bool success,) = _to.call{value: _value}(_data);
        require(success, "External call failed");
    }

    /// @notice Fallback function that allows the contract to receive Ether.
    receive() external payable {}
}

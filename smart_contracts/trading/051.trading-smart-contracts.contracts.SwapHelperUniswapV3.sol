// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import {ISwapHelperUniswapV3} from "./interfaces/ISwapHelperUniswapV3.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contractsV3/token/ERC20/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contractsV3/access/AccessControl.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

/**
 * @title The contract implements the token swap functionality through
 * UniswapV3 smart contracts. Using oracle we calculate the minimum price per swap;
 */
contract SwapHelperUniswapV3 is ISwapHelperUniswapV3, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");

    uint256 public constant PRECISION = 1000000;

    ISwapRouter public immutable swapRouter;
    IUniswapV3Factory public immutable factory;

    uint256 private _slippage;
    uint32 private _secondsAgoDefault;

    /**
     * @dev See {ISwapHelperV3}
     */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 fee,
        uint32 secondsAgo
    ) public view override returns (uint256 amountOut) {
        address pool = IUniswapV3Factory(factory).getPool(tokenIn, tokenOut, fee);
        require(pool != address(0), "pool doesn't exist");
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 tick = int24(tickCumulativesDelta / secondsAgo);
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) tick--;
        amountOut = OracleLibrary.getQuoteAtTick(tick, amountIn, tokenIn, tokenOut);
    }

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
        if (tokenA < tokenB) {
            return (tokenA, tokenB);
        } else {
            return (tokenB, tokenA);
        }
    }

    /**
     * @notice Returns a seconds ago default param
     */
    function secondsAgoDefault() external view returns (uint256) {
        return _secondsAgoDefault;
    }

    /**
     * @notice Returns a slippage for calculate price
     */
    function slippage() external view returns (uint256) {
        return _slippage;
    }

    /**
     * @notice Creates an instance of a contract that allows you to do
     * a single swap on smart contracts UniswapV3 and sends an `outputToken` to the address
     * @param swapRouter_ Swap router address for exchange
     * @param factory_ Factory address
     * @param slippage_ Maximum slippage for swap
     * @param secondsAgoDefault_ Number of seconds from the current time to query the average
     * price for the period
     */
    constructor(address swapRouter_, address factory_, uint256 slippage_, uint32 secondsAgoDefault_) {
        require(swapRouter_ != address(0), "swapRouter is zero address");
        require(factory_ != address(0), "factory is zero address");
        require(slippage_ <= PRECISION, "slippage gt precision");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        swapRouter = ISwapRouter(swapRouter_);
        factory = IUniswapV3Factory(factory_);
        _slippage = slippage_;
        _secondsAgoDefault = secondsAgoDefault_;
    }

    /**
     * @dev See {ISwapHelperV3}
     */
    function swap(
        address beneficiary,
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 fee
    ) external override returns (uint256 amountOut) {
        require(beneficiary != address(0), "beneficiary is zero address");
        require(tokenIn != address(0), "tokenIn is zero address");
        require(tokenOut != address(0), "tokenOut is zero address");
        require(amountIn > 0, "amountIn is not positive");
        IERC20 token = IERC20(tokenIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);
        token.safeApprove(address(swapRouter), amountIn);
        uint256 amountOutEstimated = getAmountOut(tokenIn, tokenOut, amountIn, fee, _secondsAgoDefault);
        uint256 amountOutMinimum = amountOutEstimated - ((amountOutEstimated * _slippage) / PRECISION);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: beneficiary,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);
        emit Swapped(beneficiary, tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @dev See {ISwapHelperV3}
     */
    function swapWithCustomSlippage(
        address beneficiary,
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 fee,
        uint256 slippageForSwap
    ) external override returns (uint256 amountOut) {
        require(beneficiary != address(0), "beneficiary is zero address");
        require(tokenIn != address(0), "tokenIn is zero address");
        require(tokenOut != address(0), "tokenOut is zero address");
        require(amountIn > 0, "amountIn is not positive");
        require(slippageForSwap > 0, "zero slippage");
        require(slippageForSwap < PRECISION, "unsafe slippage");
        IERC20 token = IERC20(tokenIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);
        token.safeApprove(address(swapRouter), amountIn);
        uint256 amountOutEstimated = getAmountOut(tokenIn, tokenOut, amountIn, fee, _secondsAgoDefault);
        uint256 amountOutMinimum = amountOutEstimated - ((amountOutEstimated * slippageForSwap) / PRECISION);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: beneficiary,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);
        emit Swapped(beneficiary, tokenIn, tokenOut, amountIn, amountOut);
    }

    /**
     * @notice Update secondsAgoDefault param responsible for the number of
     * seconds since the current moment to query the average price value (100% = 1000000)
     * @param value Number of seconds
     */
    function updateSecondsAgoDefault(uint32 value) external onlyRole(ADMIN_ROLE) returns (bool) {
        require(value != _secondsAgoDefault, "secondsAgo is the same");
        _secondsAgoDefault = value;
        emit SecondsAgoDefaultUpdated(value);
        return true;
    }

    /**
     * @notice Update slippage for calculate minimum price swap
     * @param value Number of seconds
     */
    function updateSlippage(uint256 value) external onlyRole(ADMIN_ROLE) returns (bool) {
        require(value != _slippage, "new slippage is the same");
        _slippage = value;
        emit SlippageUpdated(value);
        return true;
    }

    /**
     * @notice Modifier to check different roles
     * @param role Role `bytes32` to check availability for user
     */
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "caller does not have role");
        _;
    }
}

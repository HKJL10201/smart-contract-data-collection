// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

/******************************************************************************\
* Author: Achthar
/******************************************************************************/

import {
    MarginCallbackData,
    ExactInputMultiParams,
    ExactOutputMultiParams,
    StandaloneExactInputUniswapParams,
    MarginSwapParamsMultiExactOut
 } from "../../dataTypes/InputTypes.sol";

import {SafeCast} from "../../dex-tools/uniswap/core/SafeCast.sol";
import {TokenTransfer} from "../../libraries/TokenTransfer.sol";
import {IUniswapV3Pool} from "../../dex-tools/uniswap/core/IUniswapV3Pool.sol";
import {PoolAddressCalculator} from "../../dex-tools/uniswap/libraries/PoolAddressCalculator.sol";
import {Path} from "../../dex-tools/uniswap/libraries/Path.sol";
import {ICompoundTypeCERC20} from "../../interfaces/compound/ICompoundTypeCERC20.sol";
import {ICompoundTypeCEther} from "../../interfaces/compound/ICompoundTypeCEther.sol";
import {INativeWrapper} from "../../interfaces/INativeWrapper.sol";
import "../../libraries/LibStorage.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import "../../../periphery-standalone/interfaces/IMinimalSwapRouter.sol";
import "./BaseLendingHandler.sol";
import {UniswapDataHolder} from "../utils/UniswapDataHolder.sol";

// solhint-disable max-line-length

/**
 * @title MoneyMarket Base contract
 * @notice Contains main logic for money market interactions
 */
abstract contract BaseMoneyMarketModule is WithStorage, BaseLendingHandler, UniswapDataHolder, TokenTransfer {
    using Path for bytes;
    using SafeCast for uint256;

    uint256 private constant DEFAULT_AMOUNT_CACHED = type(uint256).max;
    address private constant DEFAULT_ADDRESS_CACHED = address(0);

    /// @dev MIN_SQRT_RATIO + 1 from Uniswap's TickMath
    uint160 private immutable MIN_SQRT_RATIO = 4295128740;
    /// @dev MAX_SQRT_RATIO - 1 from Uniswap's TickMath
    uint160 private immutable MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;

    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    constructor(
        address _factory,
        address _nativeWrapper,
        address _router
    ) BaseLendingHandler(_nativeWrapper) UniswapDataHolder(_factory, _router) {}

    function approveUnderlyings(address[] memory _underlyings) public onlyOwner {
        address _router = router;
        for (uint256 i = 0; i < _underlyings.length; i++) {
            address _underlying = _underlyings[i];
            address _cToken = address(cToken(_underlying));
            _approve(_underlying, _cToken, type(uint256).max);
            _approve(_underlying, _router, type(uint256).max);
            _approve(_cToken, _cToken, type(uint256).max);
        }
    }

    function enterMarkets(address[] memory cTokens) external onlyOwner {
        getComptroller().enterMarkets(cTokens);
    }

    // single actions with the lending protocol - all return Compound-type error codes

    function mint(address _underlying, uint256 _amountToSupply) external onlyOwner {
        _transferERC20TokensFrom(_underlying, msg.sender, address(this), _amountToSupply);
        mintPrivate(_underlying, _amountToSupply);
    }

    function redeem(
        address _underlying,
        address _recipient,
        uint256 _cAmountToRedeem
    ) external onlyOwner returns (uint256 amountWithdrawn) {
        cToken(_underlying).redeem(_cAmountToRedeem);
        amountWithdrawn = IERC20(_underlying).balanceOf(address(this));
        _transferERC20Tokens(_underlying, _recipient, amountWithdrawn);
    }

    function redeemUnderlying(
        address _underlying,
        address _recipient,
        uint256 _amountToRedeem
    ) external onlyOwner {
        redeemPrivate(_underlying, _amountToRedeem, _recipient);
    }

    function borrow(
        address _underlying,
        address _recipient,
        uint256 _borrowAmount
    ) external onlyOwner {
        borrowPrivate(_underlying, _borrowAmount, _recipient);
    }

    function repayBorrow(address _underlying, uint256 _repayAmount) external onlyOwner {
        _transferERC20TokensFrom(_underlying, msg.sender, address(this), _repayAmount);
        repayPrivate(_underlying, _repayAmount);
    }

    // direct interactions for Ether

    function mintEther() external payable onlyOwner {
        cEther().mint{value: msg.value}();
    }

    function unwrapAndMintEther(uint256 _amountToSupply) external onlyOwner {
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        _weth.transferFrom(msg.sender, address(this), _amountToSupply);
        _weth.withdraw(_amountToSupply);
        cEther().mint{value: _amountToSupply}();
    }

    function redeemCEther(address payable _recipient, uint256 _cAmountToRedeem) external onlyOwner {
        cEther().redeem(_cAmountToRedeem);
        _recipient.transfer(address(this).balance);
    }

    function redeemCEtherAndWrap(address _recipient, uint256 _cAmountToRedeem) external onlyOwner {
        cEther().redeem(_cAmountToRedeem);
        uint256 _transferAmount = address(this).balance;
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        _weth.deposit{value: _transferAmount}();
        _weth.transfer(_recipient, _transferAmount);
    }

    function redeemUnderlyingEtherAndWrap(address _recipient, uint256 _amountToRedeem) external onlyOwner {
        cEther().redeemUnderlying(_amountToRedeem);
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        _weth.deposit{value: _amountToRedeem}();
        _weth.transfer(_recipient, _amountToRedeem);
    }

    function redeemUnderlyingEther(address payable _recipient, uint256 _amountToRedeem) external onlyOwner {
        cEther().redeemUnderlying(_amountToRedeem);
        _recipient.transfer(_amountToRedeem);
    }

    function borrowEther(address payable _recipient, uint256 _borrowAmount) external onlyOwner {
        cEther().borrow(_borrowAmount);
        _recipient.transfer(_borrowAmount);
    }

    function borrowEtherAndWrap(address _recipient, uint256 _borrowAmount) external onlyOwner {
        cEther().borrow(_borrowAmount);
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        _weth.deposit{value: _borrowAmount}();
        _weth.transfer(_recipient, _borrowAmount);
    }

    function repayBorrowEther() external payable onlyOwner {
        cEther().repayBorrow{value: msg.value}();
    }

    function unwrapAndRepayBorrowEther(uint256 _repayAmount) external onlyOwner {
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        _weth.transferFrom(msg.sender, address(this), _repayAmount);
        _weth.withdraw(_repayAmount);
        cEther().repayBorrow{value: _repayAmount}();
    }

    // trade functions combined with single lending protocol action

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getUniswapV3Pool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddressCalculator.computeAddress(v3Factory, tokenA, tokenB, fee));
    }

    function swapAndSupplyExactIn(ExactInputMultiParams calldata params) external onlyOwner {
        address tokenIn = params.path.getFirstToken();
        uint256 amountIn = params.amountIn;
        _transferERC20TokensFrom(tokenIn, msg.sender, address(this), amountIn);
        // approve minimal router
        _approve(tokenIn, router, amountIn);
        // swap to self
        uint256 amountToSupply = IMinimalSwapRouter(router).exactInputToSelfWithLimit(params);
        // deposit received amount to the lending protocol on behalf of user
        mintPrivate(params.path.getLastToken(), amountToSupply);
    }

    function swapETHAndSupplyExactIn(ExactInputMultiParams calldata params) external payable onlyOwner {
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        uint256 amountIn = msg.value;
        // wrap eth
        _weth.deposit{value: amountIn}();
        _weth.approve(router, amountIn);
        // swap to self
        uint256 amountToSupply = IMinimalSwapRouter(router).exactInputToSelfWithLimit(params);
        // deposit received amount to the lending protocol on behalf of user
        mintPrivate(params.path.getLastToken(), amountToSupply);
    }

    function swapAndSupplyExactOut(MarginSwapParamsMultiExactOut calldata params) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = params.path.decodeFirstPool();
        MarginCallbackData memory data = MarginCallbackData({path: params.path, tradeType: 12, exactIn: false});
        acs().cachedAddress = msg.sender;
        uint256 amountOut = params.amountOut;
        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(data)
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        acs().cachedAddress = DEFAULT_ADDRESS_CACHED;
        require(params.amountInMaximum >= amountIn, "Paid too much");

        // deposit received amount to the lending protocol on behalf of user
        mintPrivate(tokenOut, amountOut);
    }

    function swapETHAndSupplyExactOut(ExactOutputMultiParams calldata params) external payable onlyOwner returns (uint256 amountIn) {
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        uint256 amountSent = msg.value;
        _weth.deposit{value: amountSent}();
        _weth.approve(router, amountSent);
        // use the swap router to swap exact out
        amountIn = IMinimalSwapRouter(router).exactOutputToSelfWithLimit(params);
        // deposit received amount to the lending protocol on behalf of user
        mintPrivate(params.path.getFirstToken(), params.amountOut);
        // refund dust - reverts if lippage too high
        uint256 dust = amountSent - amountIn;
        _weth.withdraw(dust);
        payable(msg.sender).transfer(dust);
    }

    function withdrawAndSwapExactIn(ExactInputParams calldata params) external onlyOwner returns (uint256 amountOut) {
        address tokenIn = params.path.getFirstToken();
        uint256 amountToWithdraw = params.amountIn;
        // withraw and send funds to this address for swaps
        redeemPrivate(tokenIn, amountToWithdraw, address(this));
        // approve router
        _approve(tokenIn, router, type(uint256).max);
        amountOut = IMinimalSwapRouter(router).exactInput(params);
    }

    function withdrawAndSwapExactInToETH(ExactInputMultiParams calldata params) external onlyOwner returns (uint256 amountOut) {
        address tokenIn = params.path.getFirstToken();
        uint256 amountToWithdraw = params.amountIn;
        // withraw and send funds to this address for swaps
        redeemPrivate(tokenIn, amountToWithdraw, address(this));
        // approve router
        _approve(tokenIn, router, type(uint256).max);
        amountOut = IMinimalSwapRouter(router).exactInputToSelfWithLimit(params);
        INativeWrapper(nativeWrapper).withdraw(amountOut);
        payable(msg.sender).transfer(amountOut);
    }

    function withdrawAndSwapExactOut(MarginSwapParamsMultiExactOut calldata params) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = params.path.decodeFirstPool();
        MarginCallbackData memory data = MarginCallbackData({path: params.path, tradeType: 14, exactIn: false});
        acs().cachedAddress = msg.sender;
        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            msg.sender,
            zeroForOne,
            -params.amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(data)
        );
        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        acs().cachedAddress = DEFAULT_ADDRESS_CACHED;
        require(params.amountInMaximum >= amountIn, "Had to withdraw too much");
    }

    function withdrawAndSwapExactOutToETH(MarginSwapParamsMultiExactOut calldata params) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = params.path.decodeFirstPool();
        uint256 amountOut = params.amountOut;
        MarginCallbackData memory data = MarginCallbackData({path: params.path, tradeType: 14, exactIn: false});
        acs().cachedAddress = msg.sender;
        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(data)
        );
        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        acs().cachedAddress = DEFAULT_ADDRESS_CACHED;
        require(params.amountInMaximum >= amountIn, "Had to withdraw too much");
        INativeWrapper(tokenOut).withdraw(amountOut);
        payable(msg.sender).transfer(amountOut);
    }

    function borrowAndSwapExactIn(ExactInputParams calldata params) external onlyOwner returns (uint256 amountOut) {
        address tokenIn = params.path.getFirstToken();
        uint256 amountIn = params.amountIn;
        // borrow and send funds to this address for swaps
        borrowPrivate(tokenIn, amountIn, address(this));
        // approve minimal router
        _approve(tokenIn, router, amountIn);
        // swap exact in with common router
        amountOut = IMinimalSwapRouter(router).exactInput(params);
    }

    function borrowAndSwapExactInToETH(StandaloneExactInputUniswapParams calldata params) external onlyOwner returns (uint256 amountOut) {
        address tokenIn = params.path.getFirstToken();
        uint256 amountIn = params.amountIn;
        // borrow and send funds to this address for swaps
        borrowPrivate(tokenIn, amountIn, address(this));
        // approve minimal router
        _approve(tokenIn, router, amountIn);
        // swap exact in with common router
        amountOut = IMinimalSwapRouter(router).exactInputToSelf(MinimalExactInputMultiParams({path: params.path, amountIn: params.amountIn}));
        require(amountOut >= params.amountOutMinimum, "Received too little");
        INativeWrapper(nativeWrapper).withdraw(amountOut);
        payable(msg.sender).transfer(amountOut);
    }

    function borrowAndSwapExactOut(MarginSwapParamsMultiExactOut calldata params) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = params.path.decodeFirstPool();
        MarginCallbackData memory data = MarginCallbackData({path: params.path, tradeType: 13, exactIn: false});
        acs().cachedAddress = msg.sender;
        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            msg.sender,
            zeroForOne,
            -params.amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(data)
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        acs().cachedAddress = DEFAULT_ADDRESS_CACHED;
        require(params.amountInMaximum >= amountIn, "Had to borrow too much");
    }

    function borrowAndSwapExactOutToETH(MarginSwapParamsMultiExactOut calldata params) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = params.path.decodeFirstPool();
        MarginCallbackData memory data = MarginCallbackData({path: params.path, tradeType: 13, exactIn: false});
        acs().cachedAddress = msg.sender;
        uint256 amountOut = params.amountOut;
        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(data)
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        acs().cachedAddress = DEFAULT_ADDRESS_CACHED;
        require(params.amountInMaximum >= amountIn, "Had to borrow too much");

        INativeWrapper(nativeWrapper).withdraw(amountOut);
        payable(msg.sender).transfer(amountOut);
    }

    function swapAndRepayExactIn(ExactInputMultiParams calldata params) external onlyOwner returns (uint256 amountOut) {
        address tokenIn = params.path.getFirstToken();
        uint256 amountIn = params.amountIn;
        _transferERC20TokensFrom(tokenIn, msg.sender, address(this), amountIn);
        // approve minimal router
        _approve(tokenIn, router, amountIn);
        // swap to self
        amountOut = IMinimalSwapRouter(router).exactInputToSelfWithLimit(params);
        // deposit received amount to the lending protocol on behalf of user
        repayPrivate(params.path.getLastToken(), amountOut);
    }

    function swapETHAndRepayExactIn(ExactInputMultiParams calldata params) external payable onlyOwner returns (uint256 amountOut) {
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        // wrap eth
        _weth.deposit{value: msg.value}();
        _weth.approve(router, type(uint256).max);
        // swap to self
        amountOut = IMinimalSwapRouter(router).exactInputToSelfWithLimit(params);
        // deposit received amount to the lending protocol on behalf of user
        repayPrivate(params.path.getLastToken(), amountOut);
    }

    function swapAndRepayExactOut(MarginSwapParamsMultiExactOut calldata params) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = params.path.decodeFirstPool();
        MarginCallbackData memory data = MarginCallbackData({path: params.path, tradeType: 12, exactIn: false});
        acs().cachedAddress = msg.sender;
        uint256 amountOut = params.amountOut;
        bool zeroForOne = tokenIn < tokenOut;
        getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(data)
        );

        amountIn = ncs().amount;
        ncs().amount = DEFAULT_AMOUNT_CACHED;
        acs().cachedAddress = DEFAULT_ADDRESS_CACHED;
        require(params.amountInMaximum >= amountIn, "Had to pay too much");

        // deposit received amount to the lending protocol on behalf of user
        repayPrivate(tokenOut, amountOut);
    }

    function swapETHAndRepayExactOut(ExactOutputMultiParams calldata params) external payable onlyOwner returns (uint256 amountIn) {
        INativeWrapper _weth = INativeWrapper(nativeWrapper);
        uint256 amountSent = msg.value;
        _weth.deposit{value: amountSent}();
        _weth.approve(router, amountSent);

        // use the swap router to swap exact out
        amountIn = IMinimalSwapRouter(router).exactOutputToSelfWithLimit(params);

        // deposit received amount to the lending protocol on behalf of user
        repayPrivate(params.path.getFirstToken(), params.amountOut);

        // refund dust
        uint256 dust = amountSent - amountIn;
        _weth.withdraw(dust);
        payable(msg.sender).transfer(dust);
    }
}

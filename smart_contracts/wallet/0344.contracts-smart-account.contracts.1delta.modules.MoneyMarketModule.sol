// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

import {IDataProvider, IComptroller, ICompoundTypeCERC20, ICompoundTypeCEther} from "../interfaces/IDataProvider.sol";
import {ICompoundTypeCToken} from "../interfaces/compound/ICompoundTypeCToken.sol";
import "./base/BaseMoneyMarketModule.sol";
import {CompoundHandler} from "./utils/CompoundHandler.sol";

// solhint-disable max-line-length

/**
 * @title MoneyMarketOperator contract
 * @notice Allows interaction of account contract with cTokens as defined by the Compound protocol
 * @author Achthar
 */
contract MoneyMarketModule is CompoundHandler, BaseMoneyMarketModule {
    constructor(
        address _factory,
        address _weth,
        address _router
    ) BaseMoneyMarketModule(_factory, _weth, _router) CompoundHandler(_weth) {}

    function mintPrivate(address token, uint256 valueToDeposit) internal override(CompoundHandler, BaseLendingHandler) {
        super.mintPrivate(token, valueToDeposit);
    }

    function redeemPrivate(
        address token,
        uint256 valueToWithdraw,
        address recipient
    ) internal override(CompoundHandler, BaseLendingHandler) {
        super.redeemPrivate(token, valueToWithdraw, recipient);
    }

    function redeemCTokenPrivate(
        address token,
        uint256 cTokenAmountToRedeem,
        address recipient
    ) internal override(CompoundHandler, BaseLendingHandler) returns (uint256) {
        return super.redeemCTokenPrivate(token, cTokenAmountToRedeem, recipient);
    }

    function redeemAllCToken(address token, address recipient) internal override(CompoundHandler, BaseLendingHandler) returns (uint256) {
        return super.redeemAllCToken(token, recipient);
    }

    function redeemAllCTokenAndKeep(address token) internal override(CompoundHandler, BaseLendingHandler) returns (uint256) {
        return super.redeemAllCTokenAndKeep(token);
    }

    function borrowPrivate(
        address token,
        uint256 valueToBorrow,
        address recipient
    ) internal override(CompoundHandler, BaseLendingHandler) {
        super.borrowPrivate(token, valueToBorrow, recipient);
    }

    function repayPrivate(address token, uint256 valueToRepay) internal override(CompoundHandler, BaseLendingHandler) {
        return super.repayPrivate(token, valueToRepay);
    }

    function cToken(address underlying) internal view override(CompoundHandler, BaseLendingHandler) returns (ICompoundTypeCERC20) {
        return super.cToken(underlying);
    }

    function cEther() internal view override(CompoundHandler, BaseLendingHandler) returns (ICompoundTypeCEther) {
        return super.cEther();
    }

    function getComptroller() internal view override returns (IComptroller) {
        return IDataProvider(ps().dataProvider).getComptroller();
    }

    function balanceOfUnderlying(address underlying) internal virtual override returns (uint256) {
        return cToken(underlying).balanceOfUnderlying(address(this));
    }

    function borrowBalanceCurrent(address underlying) internal virtual override returns (uint256) {
        return cToken(underlying).borrowBalanceCurrent(address(this));
    }

    function cTokenPair(address underlying, address underlyingOther) internal view override returns (address, address) {
        return IDataProvider(ps().dataProvider).cTokenPair(underlying, underlyingOther);
    }
    
    function cTokenAddress(address underlying) internal view override returns (address) {
        return IDataProvider(ps().dataProvider).cTokenAddress(underlying);
    }


}

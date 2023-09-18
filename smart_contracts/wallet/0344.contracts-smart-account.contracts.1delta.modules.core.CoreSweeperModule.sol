// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

import "../base/BaseSweeperModule.sol";
import {ICompoundTypeCToken} from "../../interfaces/compound/ICompoundTypeCToken.sol";
import {LendingHandler} from "./LendingHandler.sol";

// solhint-disable max-line-length

/**
 * @title MoneyMarketOperator contract
 * @notice Allows interaction of account contract with cTokens as defined by the Compound protocol
 * @author Achthar
 */
abstract contract CoreSweeperModule is LendingHandler, BaseSweeperModule {
    constructor(
        address _uniFactoryV2,
        address _uniFactoryV3,
        address _nativeWrapper,
        address _router
    ) BaseSweeperModule(_uniFactoryV2, _uniFactoryV3, _nativeWrapper, _router) LendingHandler(_nativeWrapper) {}

    function mintPrivate(address token, uint256 valueToDeposit) internal override(LendingHandler, BaseLendingHandler) {
        super.mintPrivate(token, valueToDeposit);
    }

    function redeemPrivate(
        address token,
        uint256 valueToWithdraw,
        address recipient
    ) internal override(LendingHandler, BaseLendingHandler) {
        super.redeemPrivate(token, valueToWithdraw, recipient);
    }

    function redeemCTokenPrivate(
        address token,
        uint256 cTokenAmountToRedeem,
        address recipient
    ) internal override(LendingHandler, BaseLendingHandler) returns (uint256) {
        return super.redeemCTokenPrivate(token, cTokenAmountToRedeem, recipient);
    }

    function redeemAllCToken(address token, address recipient) internal override(LendingHandler, BaseLendingHandler) returns (uint256) {
        return super.redeemAllCToken(token, recipient);
    }

    function redeemAllCTokenAndKeep(address token) internal override(LendingHandler, BaseLendingHandler) returns (uint256) {
        return super.redeemAllCTokenAndKeep(token);
    }

    function borrowPrivate(
        address token,
        uint256 valueToBorrow,
        address recipient
    ) internal override(LendingHandler, BaseLendingHandler) {
        super.borrowPrivate(token, valueToBorrow, recipient);
    }

    function repayPrivate(address token, uint256 valueToRepay) internal override(LendingHandler, BaseLendingHandler) {
        return super.repayPrivate(token, valueToRepay);
    }

    function cToken(address _underlying) internal view virtual override(BaseLendingHandler, LendingHandler) returns (ICompoundTypeCERC20);

    function cEther() internal view virtual override(BaseLendingHandler, LendingHandler) returns (ICompoundTypeCEther);

    function balanceOfUnderlying(address underlying) internal virtual override returns (uint256) {
        return cToken(underlying).balanceOfUnderlying(address(this));
    }

    function borrowBalanceCurrent(address underlying) internal virtual override returns (uint256) {
        return cToken(underlying).borrowBalanceCurrent(address(this));
    }
}

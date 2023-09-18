// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

/******************************************************************************\
* Author: Achthar
/******************************************************************************/

import {ICompoundTypeCERC20} from "../../interfaces/compound/ICompoundTypeCERC20.sol";
import {ICompoundTypeCEther} from "../../interfaces/compound/ICompoundTypeCEther.sol";
import {IComptroller} from "../../interfaces/compound/IComptroller.sol";

// solhint-disable max-line-length

/// @title Abstract module for handling transfers related to a Compound-type lending protocol
abstract contract BaseLendingHandler {
    address internal immutable nativeWrapper;

    constructor(address _nativeWrapper) {
        nativeWrapper = _nativeWrapper;
    }

    /// @param token The token to pay
    /// @param valueToDeposit The amount to deposit
    function mintPrivate(address token, uint256 valueToDeposit) internal virtual;

    /// @param token The token to pay
    /// @param valueToWithdraw The amount to withdraw
    function redeemPrivate(
        address token,
        uint256 valueToWithdraw,
        address recipient
    ) internal virtual;

    /// @param token The token to pay
    /// @param cTokenAmountToRedeem The cToken amount to redeem
    function redeemCTokenPrivate(
        address token,
        uint256 cTokenAmountToRedeem,
        address recipient
    ) internal virtual returns (uint256);

    /// @param token The token to redeem
    /// @notice redeems full balance of cToken and returns the amount of underlying withdrawn
    function redeemAllCToken(address token, address recipient) internal virtual returns (uint256);

    /// @param token The token to redeem
    /// @notice redeems full balance of cToken and returns the amount of underlying withdrawn
    function redeemAllCTokenAndKeep(address token) internal virtual returns (uint256);

    /// @param token The token to pay
    /// @param valueToBorrow The amount to borrow
    function borrowPrivate(
        address token,
        uint256 valueToBorrow,
        address recipient
    ) internal virtual;

    /// @param token The token to pay
    /// @param valueToRepay The amount to repay
    function repayPrivate(address token, uint256 valueToRepay) internal virtual;

    function cToken(address underlying) internal view virtual returns (ICompoundTypeCERC20);

    function cTokenAddress(address underlying) internal view virtual returns (address);

    function cTokenPair(address underlying, address underlyingOther) internal view virtual returns (address, address);

    function cEther() internal view virtual returns (ICompoundTypeCEther);

    function getComptroller() internal view virtual returns (IComptroller);

    // optional overrides - includes handling Ether and ERC20s
    function balanceOfUnderlying(address underlying) internal virtual returns (uint256) {}

    function borrowBalanceCurrent(address underlying) internal virtual returns (uint256) {}
}

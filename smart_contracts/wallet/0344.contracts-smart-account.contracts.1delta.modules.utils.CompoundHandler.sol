// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

/******************************************************************************\
* Author: Achthar
/******************************************************************************/

import {IERC20} from "../../dex-tools/uniswap/libraries/TransferHelper.sol";
import {IDataProvider, ICompoundTypeCERC20, ICompoundTypeCEther} from "../../interfaces/IDataProvider.sol";
import {WithStorage} from "../../libraries/LibStorage.sol";
import {INativeWrapper} from "../../interfaces/INativeWrapper.sol";
import {TokenTransfer} from "../../libraries/TokenTransfer.sol";

// solhint-disable max-line-length

/// @title Module for handling transfers from and to the Compound protocol
abstract contract CompoundHandler is WithStorage, TokenTransfer {
    address private immutable nativeWrapper;

    constructor(address _weth) {
        nativeWrapper = _weth;
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        uint256 value
    ) internal virtual {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper && address(this).balance >= value) {
            // pay with nativeWrapper
            _depositWeth(_nativeWrapper, value); // wrap only what is needed to pay
            _transferERC20Tokens(_nativeWrapper, msg.sender, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            _transferERC20Tokens(token, msg.sender, value);
        } else {
            // pull payment
            _transferERC20TokensFrom(token, payer, msg.sender, value);
        }
    }

    /// @param token The token to pay
    /// @param valueToDeposit The amount to pay
    function mintPrivate(address token, uint256 valueToDeposit) internal virtual {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw WETH
            INativeWrapper(_nativeWrapper).withdraw(valueToDeposit); // unwrap
            // deposit ETH
            cEther().mint{value: valueToDeposit}();
        } else {
            // deposit regular ERC20
            cToken(token).mint(valueToDeposit);
        }
    }

    /// @param token The token to pay
    /// @param valueToWithdraw The amount to pay
    function redeemPrivate(
        address token,
        uint256 valueToWithdraw,
        address recipient
    ) internal virtual {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw ETH from cETH
            cEther().redeemUnderlying(valueToWithdraw);
            // withdraw WETH
            INativeWrapper(_nativeWrapper).deposit{value: valueToWithdraw}(); // unwrap
            // transfer WETH
            _transferERC20Tokens(_nativeWrapper, recipient, valueToWithdraw);
        } else {
            // deposit regular ERC20
            cToken(token).redeemUnderlying(valueToWithdraw);
            // repay ERC20
            _transferERC20Tokens(token, recipient, valueToWithdraw);
        }
    }

    /// @notice the Compound protocol uses cETH for ETH deposits
    /// as Uniswap uses only WETH in their interactions, we have to withdraw the ETH from
    /// the WETH contract to then deposit (mint cETH) on Compound
    /// @param token The token to pay
    /// @param valueToWithdraw The amount to pay
    function redeemCTokenPrivate(
        address token,
        uint256 valueToWithdraw,
        address recipient
    ) internal virtual returns (uint256 underlyingAmount) {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw ETH from cETH
            cEther().redeem(valueToWithdraw);
            // record balance
            underlyingAmount = address(this).balance;
            // withdraw WETH
            INativeWrapper(_nativeWrapper).deposit{value: underlyingAmount}(); // unwrap
            // transfer WETH
            _transferERC20Tokens(_nativeWrapper, recipient, underlyingAmount);
        } else {
            // deposit regular ERC20
            cToken(token).redeemUnderlying(underlyingAmount);
            // record balance
            underlyingAmount = IERC20(token).balanceOf(address(this));
            // repay ERC20
            _transferERC20Tokens(token, recipient, underlyingAmount);
        }
    }

    /// @param token The token to redeem
    /// @notice redeems full balance of cToken and returns the amount of underlying withdrawn
    function redeemAllCToken(address token, address recipient) internal virtual returns (uint256 underlyingAmount) {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw ETH from cETH
            cEther().redeem(cEther().balanceOf(address(this)));
            // record balance of this account
            underlyingAmount = address(this).balance;
            // withdraw WETH
            INativeWrapper(_nativeWrapper).deposit{value: underlyingAmount}(); // unwrap
            // transfer WETH
            _transferERC20Tokens(_nativeWrapper, recipient, underlyingAmount);
        } else {
            // deposit regular ERC20
            cToken(token).redeem(cToken(token).balanceOf((address(this))));
            // record balance of this account
            underlyingAmount = IERC20(token).balanceOf(address(this));
            // repay ERC20
            _transferERC20Tokens(token, recipient, underlyingAmount);
        }
    }

    /// @param token The token to redeem
    /// @notice redeems full balance of cToken and returns the amount of underlying withdrawn
    function redeemAllCTokenAndKeep(address token) internal virtual returns (uint256 underlyingAmount) {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw ETH from cETH
            cEther().redeem(cEther().balanceOf(address(this)));
            // record balance of this account
            underlyingAmount = address(this).balance;
            // withdraw WETH
            INativeWrapper(_nativeWrapper).deposit{value: underlyingAmount}(); // unwrap
        } else {
            // deposit regular ERC20
            cToken(token).redeem(cToken(token).balanceOf((address(this))));
            // record balance of this account
            underlyingAmount = IERC20(token).balanceOf(address(this));
        }
    }

    /// @param token The token to pay
    /// @param valueToBorrow The amount to borrow
    function borrowPrivate(
        address token,
        uint256 valueToBorrow,
        address recipient
    ) internal virtual {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // borrow ETH
            cEther().borrow(valueToBorrow);
            // deposit ETH for wETH
            INativeWrapper(_nativeWrapper).deposit{value: valueToBorrow}();
            // transfer WETH
            _transferERC20Tokens(_nativeWrapper, recipient, valueToBorrow);
        } else {
            // borrow regular ERC20
            cToken(token).borrow(valueToBorrow);
            // transfer ERC20
            _transferERC20Tokens(token, recipient, valueToBorrow);
        }
    }

    /// @param token The token to pay
    /// @param valueToRepay The amount to repay
    function repayPrivate(address token, uint256 valueToRepay) internal virtual {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw WETH
            INativeWrapper(_nativeWrapper).withdraw(valueToRepay); // unwrap
            // repay ETH
            cEther().repayBorrow{value: valueToRepay}();
        } else {
            // repay  regular ERC20
            cToken(token).repayBorrow(valueToRepay);
        }
    }

    function cToken(address underlying) internal view virtual returns (ICompoundTypeCERC20) {
        return IDataProvider(ps().dataProvider).cToken(underlying);
    }

    function cEther() internal view virtual returns (ICompoundTypeCEther) {
        return IDataProvider(ps().dataProvider).cEther();
    }
}

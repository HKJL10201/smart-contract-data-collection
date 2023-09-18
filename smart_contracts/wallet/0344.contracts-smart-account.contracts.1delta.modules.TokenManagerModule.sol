// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.21;

import "../libraries/LibStorage.sol";
import {LibStorage} from "../libraries/LibStorage.sol";
import {IDataProvider} from "../interfaces/IDataProvider.sol";
import {TokenTransfer} from "../libraries/TokenTransfer.sol";

    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

// solhint-disable max-line-length

/**
 * @title TokenManager contract
 * @notice Allows interaction of account contract with any tokens of which there are balances
 * @author Achthar
 */
contract TokenManagerModule is WithStorage, TokenTransfer {
    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    function approveSpending(
        address _token,
        address _spender,
        uint256 _amountToApprove
    ) external onlyOwner {
        _approve(_token, _spender, _amountToApprove);
    }

    function withdrawToken(address _token, uint256 _amountToWithdraw) external onlyOwner {
        _transferERC20Tokens(_token, msg.sender, _amountToWithdraw);
    }

    function withdrawEther(address payable _recipient, uint256 _amountToWithdraw) external onlyOwner {
        _recipient.transfer(_amountToWithdraw);
    }

    function approveCTokens(address[] memory _cTokens) external onlyOwner {
        for (uint256 i = 0; i < _cTokens.length; i++) {
            address _cToken = _cTokens[i];
            address _underlying = address(IDataProvider(ps().dataProvider).underlying(_cToken));
            _approve(_cToken, _cToken, type(uint256).max);
            if (_underlying != address(0)) {
                _approve(_underlying, _cToken, type(uint256).max);
            }
        }
    }

    function enterLendingMarkets(address[] memory cTokens) external onlyOwner {
        IDataProvider(ps().dataProvider).getComptroller().enterMarkets(cTokens);
    }

    function exitLendingMarkets(address[] memory cTokens) external onlyOwner {
        for (uint256 i = 0; i < cTokens.length; i++) {
            uint256 result = IDataProvider(ps().dataProvider).getComptroller().exitMarket(cTokens[i]);
            if(result == 0) continue;
            if(result == uint(Error.NONZERO_BORROW_BALANCE)) revert("NONZERO_BORROW_BALANCE");
            if(result == uint(Error.REJECTION)) revert("REJECTION");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IComptroller} from "./compound/IComptroller.sol";
import {ICompoundTypeCERC20} from "./compound/ICompoundTypeCERC20.sol";
import {ICompoundTypeCEther} from "./compound/ICompoundTypeCEther.sol";
import {INativeWrapper} from "./INativeWrapper.sol";

// solhint-disable max-line-length

interface IDataProvider {
    function cToken(address _underlying) external view returns (ICompoundTypeCERC20);

    function cEther() external view returns (ICompoundTypeCEther);

    function nativeWrapper() external view returns (INativeWrapper);

    function minimalRouter() external view returns (address);

    function cTokens(address _underlyingIn, address _underlyingOut) external view returns (ICompoundTypeCERC20, ICompoundTypeCERC20);

    function underlying(address _cToken) external view returns (address);

    function getCollateralSwapData(
        address _underlyingFrom,
        address _underlyingTo,
        uint24 _fee
    )
        external
        view
        returns (
            ICompoundTypeCERC20 cTokenFrom,
            ICompoundTypeCERC20 cTokenTo,
            address swapPool
        );

    function getV3Pool(
        address _underlyingFrom,
        address _underlyingTo,
        uint24 _fee
    ) external view returns (address);

    function validatePoolAndFetchCTokens(
        address _pool,
        address _underlyingIn,
        address _underlyingOut
    ) external view returns (ICompoundTypeCERC20, ICompoundTypeCERC20);

    function getComptroller() external view returns (IComptroller);

    function allCTokens() external view returns (address[] memory cTokens);

    function allUnderlyings() external view returns (address[] memory underlyings);

    function cTokenPair(address _underlying, address _underlyingOther) external view returns (address _cToken, address _cTokenOther);

    function cTokenAddress(address _underlying) external view returns (address _cToken);
}

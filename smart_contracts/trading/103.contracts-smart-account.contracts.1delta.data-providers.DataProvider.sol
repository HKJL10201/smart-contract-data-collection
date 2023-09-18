// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {EnumerableSet, DataProviderStorageGenesis} from "./DataProviderStorage.sol";
import {IProxy} from "../interfaces/IProxy.sol";
import "../interfaces/IDataProvider.sol";

// data provider implementation
// trade modules not regularly fetch from here as it is gas-inefficient
contract DataProvider is DataProviderStorageGenesis {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Sets this contract as the implementation for a proxy input
     * @param proxy the prox contract to accept this implementation
     */
    function _become(IProxy proxy) external {
        require(msg.sender == proxy.admin(), "only proxy admin can change brains");
        proxy._acceptImplementation();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can interact");
        _;
    }

    function addV3Pool(
        address _token0,
        address _token1,
        uint24 _fee,
        address _pool
    ) external onlyAdmin {
        v3Pools[_token0][_token1][_fee] = _pool;
        v3Pools[_token1][_token0][_fee] = _pool;
        isValidPool[_pool] = true;
    }

    function getV3Pool(
        address _underlyingFrom,
        address _underlyingTo,
        uint24 _fee
    ) external view returns (address) {
        return v3Pools[_underlyingFrom][_underlyingTo][_fee];
    }

    function validatePoolAndFetchCTokens(
        address _pool,
        address _underlyingIn,
        address _underlyingOut
    ) external view returns (ICompoundTypeCERC20 _cTokenIn, ICompoundTypeCERC20 _cTokenOut) {
        require(isValidPool[_pool], "invalid caller");
        _cTokenIn = ICompoundTypeCERC20(_cTokens[_underlyingIn]);
        _cTokenOut = ICompoundTypeCERC20(_cTokens[_underlyingOut]);
    }

    function addCToken(address _underlying, address _cToken) external onlyAdmin {
        _cTokens[_underlying] = _cToken;
        _underlyings[_cToken] = _underlying;
        cTokenIsValid[_cToken] = true;
        _allCTokens.add(_cToken);
        _allUnderlyings.add(_underlying);
    }

    function setCEther(address _cToken) external onlyAdmin {
        _cEther = _cToken;
        cTokenIsValid[_cToken] = true;
    }

    function setNativeWrapper(address _newWrapper) external onlyAdmin {
        _nativeWrapper = _newWrapper;
    }

    function setRouter(address _newRouter) external onlyAdmin {
        _minimalRouter = _newRouter;
    }

    function removeCToken(address _underlying, address _cToken) external onlyAdmin {
        delete _cTokens[_underlying];
        delete _underlyings[_cToken];
        delete cTokenIsValid[_cToken];
        _allCTokens.remove(_cToken);
        _allUnderlyings.remove(_underlying);
    }

    function cToken(address _underlying) external view returns (ICompoundTypeCERC20) {
        address _cToken = _cTokens[_underlying];
        require(cTokenIsValid[_cToken], "invalid cToken");
        return ICompoundTypeCERC20(_cToken);
    }

    function cEther() external view returns (ICompoundTypeCEther) {
        return ICompoundTypeCEther(_cEther);
    }

    function underlying(address _cToken) external view returns (address) {
        require(cTokenIsValid[_cToken], "invalid cToken");
        return _underlyings[_cToken];
    }

    function addComptroller(address _comptrollerToAdd) external onlyAdmin {
        _comptroller = _comptrollerToAdd;
    }

    function getComptroller() external view returns (IComptroller) {
        return IComptroller(_comptroller);
    }

    function allCTokens() external view returns (address[] memory cTokens) {
        cTokens = _allCTokens.values();
    }

    function allUnderlyings() external view returns (address[] memory underlyings) {
        underlyings = _allUnderlyings.values();
    }

    function nativeWrapper() external view returns (INativeWrapper) {
        return INativeWrapper(_nativeWrapper);
    }

    function minimalRouter() external view returns (address) {
        return _minimalRouter;
    }

    function cTokenPair(address _underlying, address _underlyingOther) external view returns (address _cToken, address _cTokenOther) {
        _cToken = _cTokens[_underlying];
        require(_cToken != address(0), "invalid cToken");
        _cTokenOther = _cTokens[_underlyingOther];
        require(_cTokenOther != address(0), "invalid cTokenOther");
    }

    function cTokenAddress(address _underlying) external view returns (address _cToken) {
        _cToken = _cTokens[_underlying];
        require(_cToken != address(0), "invalid cToken");
    }
}

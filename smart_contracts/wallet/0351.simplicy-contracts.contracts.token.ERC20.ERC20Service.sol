// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IERC20Service} from "./IERC20Service.sol";
import {ERC20ServiceInternal} from "./ERC20ServiceInternal.sol";
import {ERC20ServiceStorage} from "./ERC20ServiceStorage.sol";

/**
 * @title ERC20Service 
 */
abstract contract ERC20Service is
    IERC20Service,
    ERC20ServiceInternal
{
    using ERC20ServiceStorage for ERC20ServiceStorage.Layout;

    /**
     * @inheritdoc IERC20Service
     */
    function getAllTrackedERC20Tokens() external view override returns (address[] memory) {
        return _getAllTrackedERC20Tokens();
    }

    /**
     * @inheritdoc IERC20Service
     */
    function balanceOfERC20(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @inheritdoc IERC20Service
     */
    function transferERC20(address token, address to, uint256 amount) external override returns (bool) {
        _beforeTransferERC20(token, to, amount);

        return IERC20(token).transfer(to, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function transferERC20From(address token, address from, address to, uint256 amount) external returns (bool) {
        _beforeTransferERC20From(token, from, to, amount);

        return IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function approveERC20(address token, address spender, uint256 amount) external override returns (bool) {
        _beforeApproveERC20(token, spender, amount);

        return IERC20(token).approve(spender, amount);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function registerERC20(address token) external override {
        _beforeRegisterERC20(token);

        _registerERC20(token);

        _afterRegisterERC20(token);
    }

    /**
     * @inheritdoc IERC20Service
     */
    function removeERC20(address token) external override {
        _beforeRemoveERC20(token);

        _removeERC20(token);

        _afterRemoveERC20(token);
    }
}

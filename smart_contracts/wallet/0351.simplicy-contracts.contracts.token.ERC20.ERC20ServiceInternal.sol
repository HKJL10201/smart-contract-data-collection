// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

import {IERC20ServiceInternal} from "./IERC20ServiceInternal.sol";
import {ERC20ServiceStorage} from "./ERC20ServiceStorage.sol";

/**
 * @title ERC20Service internal functions, excluding optional extensions
 */
abstract contract ERC20ServiceInternal is IERC20ServiceInternal {
    using ERC20ServiceStorage for ERC20ServiceStorage.Layout;

    modifier erc20IsTracked(address tokenAddress) {
        require(_getERC20TokenIndex(tokenAddress) > 0, "ERC20Service: token not tracked");
        _;
    }

    /**
     * @notice query the mapping index of ERC20 tokens
     */
    function _getERC20TokenIndex(address tokenAddress) internal view returns (uint256) {
        return ERC20ServiceStorage.layout().erc20TokenIndex[tokenAddress];
    }

    /**
     * @notice query all tracked ERC20 tokens
     */
    function _getAllTrackedERC20Tokens() internal view returns (address[] memory) {
        return ERC20ServiceStorage.layout().erc20Tokens;
    }
   
    /**
     * @notice register a new ERC20 token
     * @param tokenAddress: the address of the ERC721 token
     */
    function _registerERC20(address tokenAddress) internal virtual {
        ERC20ServiceStorage.layout().storeERC20(tokenAddress);

        emit ERC20TokenTracked(tokenAddress);
    }

     /**
     * @notice remove a new ERC20 token from ERC20Service
     * @param tokenAddress: the address of the ERC20 token
     */
    function _removeERC20(address tokenAddress) internal virtual {
        ERC20ServiceStorage.layout().deleteERC20(tokenAddress);

        emit ERC20TokenRemoved(tokenAddress);
    }

    /**
     * @notice hook that is called before transferERC20
     */
    function _beforeTransferERC20(address token, address to, uint256 amount) internal virtual view erc20IsTracked(token) {}

    /**
     * @notice hook that is called before transferERC20From
     */
    function _beforeTransferERC20From(address token, address from, address to, uint256 amount) internal virtual view erc20IsTracked(token) {}


    /**
     * @notice hook that is called before approveERC20
     */
    function _beforeApproveERC20(address token, address spender, uint256 amount) internal virtual view erc20IsTracked(token) {}

    /**
     * @notice hook that is called before registerERC20Token
     */
    function _beforeRegisterERC20(address tokenAddress) internal virtual view {
        require(tokenAddress != address(0), "ERC20Service: tokenAddress is the zero address");
        require(_getERC20TokenIndex(tokenAddress) == 0, "ERC20Service: ERC20 token is already tracked");
    }

    /**
     * @notice hook that is called after registerERC20Token
     */
    function _afterRegisterERC20(address tokenAddress) internal virtual view {}

    /**
     * @notice hook that is called before removeERC20Token
     */
    function _beforeRemoveERC20(address tokenAddress) internal virtual view erc20IsTracked(tokenAddress) {
        require(tokenAddress != address(0), "ERC20Service: tokenAddress is the zero address");
    }

    /**
     * @notice hook that is called after removeERC20Token
     */
    function _afterRemoveERC20(address tokenAddress) internal virtual view {}
}

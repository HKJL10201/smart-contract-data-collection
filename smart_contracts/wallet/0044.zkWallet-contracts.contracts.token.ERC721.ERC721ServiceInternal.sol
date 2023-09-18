// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC721ServiceInternal} from "./IERC721ServiceInternal.sol";
import {ERC721ServiceStorage} from "./ERC721ServiceStorage.sol";

/**
 * @title ERC721Service internal functions, excluding optional extensions
 */
abstract contract ERC721ServiceInternal is IERC721ServiceInternal {
    using ERC721ServiceStorage for ERC721ServiceStorage.Layout;

    modifier erc721IsTracked(address tokenAddress) {
        require(_getERC721TokenIndex(tokenAddress) > 0, "ERC721Service: token not registered");
        _;
    }

    function _getERC721TokenIndex(address tokenAddress) internal view returns (uint256) {
        return ERC721ServiceStorage.layout().erc721TokenIndex[tokenAddress];
    }

     /**
     * @notice query all tracked ERC721 tokens
     */
    function _getAllTrackedERC721Tokens() internal view returns (address[] memory) {
        return ERC721ServiceStorage.layout().erc721Tokens;
    }
   
    /**
     * @notice register a new ERC721 token
     * @param tokenAddress: the address of the ERC721 token
     */
    function _registerERC721(address tokenAddress) internal virtual {
        ERC721ServiceStorage.layout().storeERC721(tokenAddress);

        emit ERC721TokenTracked(tokenAddress);
    }

     /**
     * @notice remove a new ERC721 token from ERC721Service
     * @param tokenAddress: the address of the ERC721 token
     */
    function _removeERC721(address tokenAddress) internal virtual {
        ERC721ServiceStorage.layout().deleteERC721(tokenAddress);

        emit ERC721TokenRemoved(tokenAddress);
    }

    /**
     * @notice hook that is called before transferERC721
     */
    function _beforeTransferERC721(address token, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after transferERC721
     */
    function _afterTransferERC721(address token, address to, uint256 tokenId) internal virtual view {}

    /**
     * @notice hook that is called before safeTransferERC721From
     */
    function _beforeSafeTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after safeTransferERC721From
     */
    function _afterSafeTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called before transferERC721From
     */
    function _beforeTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after transferERC721From
     */
    function _afterTransferERC721From(address token, address from, address to, uint256 tokenId) internal virtual view erc721IsTracked(token) {}


    /**
     * @notice hook that is called before approveERC721
     */
    function _beforeApproveERC721(address token, address spender, uint256 tokenId) internal virtual view erc721IsTracked(token) {}

    /**
     * @notice hook that is called after approveERC721
     */
    function _afterApproveERC721(address token, address spender, uint256 tokenId) internal virtual view erc721IsTracked(token) {}


    /**
     * @notice hook that is called before registerERC721
     */
    function _beforeRegisterERC721(address tokenAddress) internal virtual view {
        require(tokenAddress != address(0), "ERC721Service: tokenAddress is the zero address");
        require(_getERC721TokenIndex(tokenAddress) == 0, "ERC721Service: ERC721 token is already registered");
    }

    /**
     * @notice hook that is called after registerERC721
     */
    function _afterRegisterERC721(address tokenAddress) internal virtual view {}

     /**
     * @notice hook that is called before removeERC721
     */
    function _beforeRemoveERC721(address tokenAddress) internal virtual view {
        require(tokenAddress != address(0), "ERC721Service: tokenAddress is the zero address");
    }

     /**
     * @notice hook that is called after removeERC721
     */
    function _afterRemoveERC721(address tokenAddress) internal virtual view {}
}

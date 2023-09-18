// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721Service} from "./IERC721Service.sol";
import {ERC721ServiceInternal} from "./ERC721ServiceInternal.sol";
import {ERC721ServiceStorage} from "./ERC721ServiceStorage.sol";

/**
 * @title ERC20Service 
 */
abstract contract ERC721Service is
    IERC721Service,
    ERC721ServiceInternal
{
    using ERC721ServiceStorage for ERC721ServiceStorage.Layout;

    /**
     * @inheritdoc IERC721Service
     */
    function getAllTrackedERC721Tokens() external view override returns (address[] memory) {
        return _getAllTrackedERC721Tokens();
    }

    /**
     * @inheritdoc IERC721Service
     */
    function balanceOfERC721(address token) external view override returns (uint256) {
        return IERC721(token).balanceOf(address(this));
    }

    /**
     * @inheritdoc IERC721Service
     */
    function ownerOfERC721(address token, uint256 tokenId) external view override returns (address owner) {
        return IERC721(token).ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function transferERC721(address token, address to, uint256 tokenId) external override {
        _beforeTransferERC721(token, to, tokenId);

        IERC721(token).safeTransferFrom(to, address(this), tokenId);

        _afterTransferERC721(token, to, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function safeTransferERC721From(address token, address from, address to, uint256 tokenId, bytes calldata data) external override {
        _beforeSafeTransferERC721From(token, from, to, tokenId);

        IERC721(token).safeTransferFrom(from, to, tokenId, data);

        _afterSafeTransferERC721From(token, from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function safeTransferERC721From(address token, address from, address to, uint256 tokenId) external override {
        _beforeSafeTransferERC721From(token, from, to, tokenId);

        IERC721(token).safeTransferFrom(from, to, tokenId);

        _afterSafeTransferERC721From(token, from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function transferERC721From(address token, address from, address to, uint256 tokenId) external override {
        _beforeTransferERC721From(token, from, to, tokenId);

        IERC721(token).safeTransferFrom(from, to, tokenId);

        _afterTransferERC721From(token, from, to, tokenId);
    }
    

    /**
     * @inheritdoc IERC721Service
     */
    function approveERC721(address token, address spender, uint256 tokenId) external override {
        _beforeApproveERC721(token, spender, tokenId);

        IERC721(token).approve(spender, tokenId);

        _afterApproveERC721(token, spender, tokenId);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function registerERC721(address token) external override {
        _beforeRegisterERC721(token);

        _registerERC721(token);

        _afterRegisterERC721(token);
    }

    /**
     * @inheritdoc IERC721Service
     */
    function removeERC721(address token) external override {
        _beforeRemoveERC721(token);

        _removeERC721(token);

        _afterRemoveERC721(token);
    }
}

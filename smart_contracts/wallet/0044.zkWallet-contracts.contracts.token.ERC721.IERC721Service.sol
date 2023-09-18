// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC721ServiceInternal} from "./IERC721ServiceInternal.sol";

/**
 * @title ERC20Service interface 
 */
interface IERC721Service is IERC721ServiceInternal {
    /**
     * @notice query all tracked ERC721 tokens
     * @return tracked ERC721  tokens
     */
    function getAllTrackedERC721Tokens() external view returns (address[] memory);

     /**
     * @notice query the token balance of the given ERC721 token for this address
     * @param token : the address of the ERC721 token
     * @return token balance
     */
    function balanceOfERC721(address token) external view returns (uint256);

    /**
     * @notice query the owner of the `tokenId` token.
     * @param token: the address of tracked token to query
     * @param tokenId: the tokenId of the token to query
     *
     */
    function ownerOfERC721(address token, uint256 tokenId) external view returns (address owner);

    /**
     * @notice safely transfers `tokenId` token from `from` to `to`
     * @param token: the address of tracked token to move
     * @param to: the address of the recipient
     * @param tokenId: the tokenId to transfer
     */
    function transferERC721(address token, address to, uint256 tokenId) external;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param token: the address of tracked token to move
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param token: the address of tracked token to move
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param token: the address of tracked token to move
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferERC721From(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice gives permission to `to` to transfer `tokenId` token to another account.
     * @param token: the address of tracked token to move
     * @param spender: the address of the spender
     * @param tokenId: the tokenId to approve
     */
    function approveERC721(address token, address spender, uint256 tokenId) external;

    /**
     * @notice register a new ERC721 token
     * @param token: the address of the ERC721 token
     */
    function registerERC721(address token) external;

    /**
     * @notice remove a new ERC721 token from ERC721Service
     * @param token: the address of the ERC721 token
     */
    function removeERC721(address token) external;
}

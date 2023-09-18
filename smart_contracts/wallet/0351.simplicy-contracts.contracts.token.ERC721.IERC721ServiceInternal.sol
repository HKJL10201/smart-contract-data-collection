// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial ERC721Service interface needed by internal functions
 */
interface IERC721ServiceInternal {
    /**
     * @notice emitted when a new ERC721 token is registered
     * @param tokenAddress: the address of the ERC721 token
     */
    event ERC721TokenTracked(address indexed tokenAddress);

    /**
     * @notice emitted when a new ERC721 token is removed
     * @param tokenAddress: the address of the ERC721 token
     */
    event ERC721TokenRemoved(address indexed tokenAddress); 
}

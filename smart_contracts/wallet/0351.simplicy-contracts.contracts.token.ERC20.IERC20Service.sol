// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20ServiceInternal} from "./IERC20ServiceInternal.sol";

/**
 * @title ERC20Service interface 
 */
interface IERC20Service is IERC20ServiceInternal {
    /**
     * @notice query all tracked ERC20 tokens
     * @return tracked ERC20 tokens
     */
    function getAllTrackedERC20Tokens() external view returns (address[] memory);

    /**
     * @notice query the token balance of the given token for this address
     * @param token : the address of the token
     * @return token balance of this address
     */
    function balanceOfERC20(address token) external view returns (uint256);

    /**
     * @notice sets `amount` as the allowance of `spender` over the caller's tokens
     * @param token: the address of tracked token to move
     * @param spender: the address of the spender
     * @param amount: the amount of tokens to set as allowance
     * @return returns a boolean value indicating whether the operation succeeded
     */
    function approveERC20(address token, address spender, uint256 amount) external returns (bool);

    /**
     * @notice moves `amount` tracked tokens from the caller's account to `to`
     * @param token: the address of tracked token to move
     * @param to: the address of the recipient
     * @param amount: the amount of tokens to move
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function transferERC20(address token, address to, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param token: the address of tracked token to move
     * @param from: holder of tokens prior to transfer
     * @param to: beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferERC20From(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice register a new ERC20 token
     * @param token: the address of the ERC721 token
     */
    function registerERC20(address token) external;

    /**
     * @notice remove a new ERC20 token from ERC20Service
     * @param token: the address of the ERC20 token
     */
    function removeERC20(address token) external;
}

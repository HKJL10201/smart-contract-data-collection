pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
/// @title  Base contract to be used to represent all ERC20 PoB tokens
/// @notice All the duster calls can emit money if successful, no function that shouldn't do that should be added
interface IDuster {

    /// @notice This method receives certain amount of tokens to be changed to Dust
    /// @param chainId Id of the chain from which the tokens belong
    /// @param tokens Amount of ERC20 tokens to destroy
    /// @return burned Amount of Dust to issue
    /// @return recipient the receiver of the transparent dust
    /// @dev This function is likely to change in order to include a way to be able to query another contract
    /// to determine the rate and the allowed amount to exchange
    function toDust(uint8 chainId, uint tokens) external returns (uint burned, address recipient);

    /// @dev This function can only be called from Claimer contract as the from is specified instead of using msg.sender
    function toDustFrom(uint8 chainId, address from, uint256 tokens) external returns (uint burned, address recipient);

}
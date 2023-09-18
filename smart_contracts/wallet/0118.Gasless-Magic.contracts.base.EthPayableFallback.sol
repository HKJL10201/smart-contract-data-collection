pragma solidity ^0.5.11;

/// @title EthPayableFallback - Is a contract providing a fallback function to accept Ether payment.
/// @notice Should be inherited by all contracts who wish to accept ether payment
/// @dev If fallback function is re-implemented in the child contract, make sure to add in function modifiers, "external" and "payable"
contract EthPayableFallback {
    /// @notice Event used for specifying received amount, triggered by Ether receivable fallback function.
    /// @dev Both input are indexed so that they are easily searchable after fired.
    event Received(uint256 indexed value, address indexed from);

    /// @notice Fallback function making child contracts accept ETH.
    /// @notice Has to have these function modifiers to be valid.
    function () external payable {
        /// @notice msg.value (uint): number of wei sent with the message
        /// @notice address of sender logged too
        emit Received(msg.value, msg.sender);
    }
}
pragma solidity >=0.5 <0.6.0;

/// @title Decay
/// @notice Interface that must comply with the contracts that calculate the current price in Dutch
/// @author Ruggiero Santo
interface Decay {
    /// @notice Calculate the current price by mapping the range [starting_block,
    ///      starting_block + block_to_live] in the range [starting_price, 0];
    ///      starting_price is not the starting price of the auction but the
    ///      maximum price in the range; talking in the context of the auction
    ///      initial_price = auction.initial_price - reserve_price
    /// @param initial_price Price of good at the start of the auction
    /// @param starting_block Start block from which the price starts to decrease
    /// @param block_to_live Number of blocks in which the auction remains alive
    function current_price(uint initial_price, uint starting_block, uint block_to_live) external view returns (uint);
}
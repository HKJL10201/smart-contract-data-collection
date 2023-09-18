pragma solidity >=0.5 <0.6.0;

import "./I_Decay.sol";

/// @title Linear
/// @notice Calculate the current price, the price decreases in a linear way with respect to the passage of time.
/// @author Ruggiero Santo
contract Linear is Decay {
    /// @notice See description of the interface
    /// @dev Draw the function of a line through the two points (0.0) and
    ///      (block_to_live, initial_price) then calculating the y by putting
    ///      x = blok.number, you have the current price in the range
    ///      [0, initial_price].
    function current_price(uint initial_price, uint starting_block, uint block_to_live) external view returns (uint) {
        if ( block.number > (starting_block + block_to_live) )
            return 0;
        else
            return initial_price * ((starting_block + block_to_live) - block.number) / block_to_live;
    }
}
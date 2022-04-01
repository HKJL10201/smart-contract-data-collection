pragma solidity >=0.5 <0.6.0;

import "./I_Decay.sol";

///  @title Linear
///  @notice Calculate the current price, the price decreases in a sup-linear way with respect to the passage of time.
///  @author Ruggiero Santo
contract Sup_Linear is Decay {
    /// @notice See description of the interface
    /// @dev Draws the function of a parabola passed for points (0.0),
    ///      (block_to_live, initial_price) and tangent to the line
    ///      y = initial_price. Then calculate the y by putting x = blok.number
    ///      I have the current price in the range [0, initial_price]. In this
    ///      way you will have an initially slow trend that will accelerate.
    function current_price(uint initial_price, uint starting_block, uint block_to_live) external view returns (uint) {
        if ( block.number > (starting_block + block_to_live) )
            return 0;
        else
            return (2*initial_price * ((starting_block + block_to_live) - block.number) / block_to_live) - ( (initial_price * ((starting_block + block_to_live) - block.number)**2) / block_to_live**2 );
    }
}
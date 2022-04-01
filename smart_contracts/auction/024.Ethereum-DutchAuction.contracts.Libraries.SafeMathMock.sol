pragma solidity ^0.4.24;

import "../Libraries/SafeMath.sol";


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
contract SafeMathMock {

    /**
      * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMath.mul(a, b);
    }

    /**
      * @dev Divides two numbers, reverts on overflow.
    */
    function div(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMath.div(a, b);
    }

    /**
      * @dev Subtracts two numbers, reverts on overflow.
    */
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMath.sub(a, b);
    }

    /**
      * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMath.add(a, b);
    }

    /**
      * @dev Modulus two numbers, reverts on overflow.
    */
    function mod(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMath.mod(a, b);
    }
}

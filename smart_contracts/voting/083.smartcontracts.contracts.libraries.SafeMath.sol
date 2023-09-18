pragma solidity ^0.5.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Flawed input for multiplication");

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Can't divide by zero");
        uint256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Can't subtract a number from a smaller one with uints");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Result has to be bigger than both summands");

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Can't perform modulo with zero");
        return a % b;
    }

    /**
    * @dev Extracts the root of a unisigned integer, reverts on overflow.
    */
    function sqrt(uint256 a) public pure returns (uint256) {
        if (a == 0) return 0;

        require(a + 1 > a, "Flawed input for sqrt");

        uint256 c = (a + 1) / 2;
        uint256 b = a;

        while (c < b) {
            b = c;
            c = (a / c + c) / 2;
        }

        return c;
    }
}
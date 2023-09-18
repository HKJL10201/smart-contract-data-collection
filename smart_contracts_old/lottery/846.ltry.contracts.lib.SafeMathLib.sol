pragma solidity ^0.4.11;


/**
 * Math operations with safety checks that throw on error
 *
 * https://blog.aragon.one/library-driven-development-in-solidity-2bebcaf88736#.750gwtwli
 *
 * Originally from https://raw.githubusercontent.com/AragonOne/zeppelin-solidity/master/contracts/SafeMath.sol
 * Maintained here until merged to mainline zeppelin-solidity.
 *
 * using SafeMathLib for uint256;
 */
library SafeMathLib {
  /**
   * Safely multiplies two large numbers a and b
   *
   * a.times(b);
   *
   * @return a * b
   */
  function times(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }


  /**
   * Safely divides two large numbers a and b
   *
   * a.div(b);
   *
   * @return a / b
   */
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0);  * Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b);  * There is no case in which this doesn't hold
    return c;
  }


  /**
   * Safely adds two large numbers a and b
   *
   * a.plus(b);
   *
   * @return a + b
   */
  function plus(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }


  /**
   * Safely subtracts two large numbers b from a
   *
   * a.minus(b);
   *
   * @return a - b
   */
  function minus(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

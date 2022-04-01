pragma solidity ^0.4.24;
import "./SafeMath.sol";

contract Fee {
  using SafeMath for uint256;
  
  function getFee(uint _base, uint _amount) external view returns (uint256 fee) {
    return _base.mul(2);
  }
}
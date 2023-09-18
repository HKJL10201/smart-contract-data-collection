// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library SafeMath {

  function add(uint number, uint amount) internal pure returns (uint) {
    return number + amount;
  }

  function sub(uint number, uint amount) internal pure returns (uint) {
    return number < amount ? 0 : number - amount;
  }

  function mull(uint number, uint amount) internal pure returns (uint) {
    return number * amount;
  }

  function div(uint number, uint amount) internal pure returns (uint) {
    return amount == 0 ? 0 : number / amount;
  }

  function pow(uint number, uint amount) internal pure returns (uint) {
    return number ** amount;
  }

  function increase(uint number) internal pure returns (uint) {
    return add(number, 1);
  }

  function decrease(uint number) internal pure returns (uint) {
    return sub(number, 1);
  }

  function between(uint number, uint min, uint max) internal pure returns (uint) {
    return (number % max) + min;
  }

  function isBetween(uint number, uint min, uint max) internal pure returns (bool) {
    return number >= min && number <= max;
  }

  function percent(uint number, uint8 _percent) internal pure returns (uint) {
    return number * _percent / 100;
  }

  function isZero(uint number) internal pure returns (bool) {
    return number == 0;
  }

  function notZero(uint number) internal pure returns (bool) {
    return number != 0;
  }

}
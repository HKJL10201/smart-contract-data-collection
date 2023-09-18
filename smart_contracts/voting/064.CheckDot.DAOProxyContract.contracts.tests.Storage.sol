// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Storage {
    using Counters for Counters.Counter;

    mapping(string => uint256) _uintStorage;
    mapping(string => address) _addressStorage;
    mapping(string => bool)    _boolStorage;
    mapping(string => string)  _stringStorage;
    mapping(string => Counters.Counter) _counterStorage;
}
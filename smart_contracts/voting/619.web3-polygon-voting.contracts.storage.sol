// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    uint256 public number;

    function store(uint256 num) public {
        number = num;
    }
}
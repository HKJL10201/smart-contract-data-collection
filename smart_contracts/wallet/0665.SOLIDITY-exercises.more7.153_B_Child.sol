//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.1;

contract Child {
    string public name;

    constructor(string memory _n) {
        name = _n;
    }
}
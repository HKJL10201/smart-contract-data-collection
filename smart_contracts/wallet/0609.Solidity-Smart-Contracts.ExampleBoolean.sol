// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract ExampleBoolean{
    bool public mybool;

    function setMyBool(bool _mybool) public {
        mybool = _mybool;
    }
}
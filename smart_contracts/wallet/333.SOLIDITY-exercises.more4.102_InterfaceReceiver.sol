//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract InterfaceReceiver {
    uint public myNumber = 5;

    function setNumber() external {
        myNumber+=3;
    }
}
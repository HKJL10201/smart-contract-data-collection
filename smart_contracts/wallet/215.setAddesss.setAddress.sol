// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract AddressExample {
    address public myAddress;

function setAddress (address _address) public {
   
    myAddress = _address;
    }

function GetBallanceFromMyAddress () public view returns (uint) {

    return myAddress.balance;

    }
}
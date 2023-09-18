// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string message = "Rinkeby";

    constructor(){

    }

    function setMassage(string memory _message) public {
        message = _message;
    }

    function getMassage() public view returns (string memory) {
        return message;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ExampleConstructor{
    string public myAddress;

    constructor(address _someAddress){
        myAddress = _someAddress;
    }

    function setMyAddress(address _myAddress) public {
        myAddress = _myAddress;
    }

    function setMyAddressToMsgSender() public {
        myAddress = msg.sender;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ExampleMsgSender {

    address public someAddress;

    function updateSomeAddress() public {
        someAddress = msg.sender; // msg is a public object. .sender contains the address of the person who is interacting with the smart contract.
    }
}
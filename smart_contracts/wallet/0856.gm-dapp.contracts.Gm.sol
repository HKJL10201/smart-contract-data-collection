//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Gm {
    address public owner;
    string private message;

    constructor() {
        owner = msg.sender;
    }

    function sendEth(address payable _to, string memory _message) payable external {
        _to.transfer(msg.value);
        message = _message;
    }
}
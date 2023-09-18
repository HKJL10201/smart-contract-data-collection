// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract HelloWorld {

    string public constant MESSAGE_CONSTANT = "Hi constant";

    address public constant DONATION_ADDRES = 0x51Dd9abcd7972612b59a26a6286Eb446cFc910d9;

    address public immutable OWNER;

    constructor() {
        OWNER = msg.sender;
    }

    function greetings() public pure returns (string memory) {
        string memory message = "Test Solidity";
        return message;
    }

    function getBlockNumber() public view returns(uint) {
        return block.number;
    }

}

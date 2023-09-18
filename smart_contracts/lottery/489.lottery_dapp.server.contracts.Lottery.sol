// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Lottery {
    address public manager;
    address payable[] public participants;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 2 ether, "Not Enough Eth");
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() private view returns (uint256) {
        return participants.length - 1;
    }

    function selectWinner() public returns (address) {
        require(msg.sender == manager);
        require(participants.length > 3);
        uint256 index = getBalance();
        participants[index].transfer(getBalance());
        return participants[index];
    }
}

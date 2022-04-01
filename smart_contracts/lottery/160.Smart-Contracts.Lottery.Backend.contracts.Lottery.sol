// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract Lottery {
    address public owner;
    address[] participants;

    constructor() {
        owner = msg.sender;
    }

    function viewParticipants() public view returns (address[] memory) {
        return participants;
    }

    function viewBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function participate() public payable {
        require(msg.value >= 0.01 ether);
        participants.push(msg.sender);
    }

    function pickWinner() public payable restricted {
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    participants
                )
            )
        ) % participants.length;
        payable(participants[index]).transfer(address(this).balance);
        delete participants;
    }

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }
}

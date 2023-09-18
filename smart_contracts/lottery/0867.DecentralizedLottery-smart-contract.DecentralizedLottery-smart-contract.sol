// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DecentralizedLottery {
    address payable[] public participants;
    address public owner;
    uint public entryFee;
    uint public maxParticipants;

    event LotteryEntered(address indexed participant);
    event LotteryWon(address indexed winner, uint prize);

    constructor(uint _entryFee, uint _maxParticipants) {
        owner = msg.sender;
        entryFee = _entryFee;
        maxParticipants = _maxParticipants;
    }

    function enterLottery() public payable {
        require(msg.value == entryFee, "Invalid entry fee.");
        require(participants.length < maxParticipants, "Max participants reached.");
        require(!isParticipant(msg.sender), "Address already participating.");

        participants.push(payable(msg.sender));

        emit LotteryEntered(msg.sender);

        if (participants.length == maxParticipants) {
            selectWinner();
        }
    }

    function isParticipant(address _address) private view returns (bool) {
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function selectWinner() private {
        require(participants.length == maxParticipants, "Not enough participants.");

        uint winnerIndex = random() % participants.length;
        address payable winner = participants[winnerIndex];

        uint prize = address(this).balance;

        winner.transfer(prize);

        emit LotteryWon(winner, prize);

        resetLottery();
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants)));
    }

    function resetLottery() private {
        delete participants;
    }
}


// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ticket {

    address public owner;
    int[6] public numbers;
    int public round;

    constructor (address ownerAddress, int[6] memory numbersPlayed, int currentRound) {
        owner = ownerAddress;
        numbers = numbersPlayed;
        round = currentRound;
    }

    function getNumbers () public view returns (int[6] memory) {
        return numbers;
    }

    function getOwner () public view returns (address) {
        return owner;
    }

    function getRound () public view returns (int) {
        return round;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ticket {

    address public owner;
    uint[6] public numbers;
    uint public round;

    constructor (address ownerAddress, uint[6] memory numbersPlayed, uint currentRound) {
        owner = ownerAddress;
        numbers = numbersPlayed;
        round = currentRound;
    }

    function getNumbers () public view returns (uint[6] memory) {
        return numbers;
    }

    function getOwner () public view returns (address) {
        return owner;
    }

    function getRound () public view returns (uint) {
        return round;
    }
}
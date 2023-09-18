// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract EvenOrOdd {
    enum Choice {Even, Odd, NeedChoose}
    Choice public evenOrOdd = Choice.NeedChoose;
    uint8 private userNumber;

    function setChoice(Choice newChoice) public {
        evenOrOdd = newChoice;
    }

    function random() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, evenOrOdd)));
    }

    function play(uint8 number) public view returns(bool) {
        require(number >= 0 && number <=5, "Play between 0 and 5");
        require(evenOrOdd != Choice.NeedChoose, "Choose even or odd. 0 for even, 1 for odd");

        uint256 cpuNumber = random();
        bool isEven = (number + cpuNumber) % 2 == 0;
        if(isEven && evenOrOdd == Choice.Even) {
            return true;
        } else if (!isEven && evenOrOdd == Choice.Odd) {
            return true;
        } else {
            return false;
        }
    }
}

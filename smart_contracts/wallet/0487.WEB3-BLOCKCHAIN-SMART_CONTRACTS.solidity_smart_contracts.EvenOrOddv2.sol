// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// npm install @openzeppelin/contracts
// import "@openzeppelin/contracts/utils/Strings.sol";

contract EvenOrOdd {
    string public evenOrOdd = ""; // EVEN or ODD
    uint8 private userNumber;

    function compare(string memory str1, string memory str2) private pure returns(bool) {
        bytes memory arrA = bytes(str1);
        bytes memory arrB = bytes(str2);
        return arrA.length == arrB.length && keccak256(arrA) == keccak256(arrB);
    }

    function setChoice(string memory newChoice) public {
        require(compare(newChoice, "EVEN") || compare(newChoice, "ODD"), "Choose EVEN or ODD");
        evenOrOdd = newChoice;
    }

    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, evenOrOdd))) % 2);
    }

    function play(uint8 number) public view returns(string memory) {
        require(number >= 0 && number <=5, "Play between 0 and 5");
        require(!compare(evenOrOdd, ""), "Choose even or odd. 0 for even, 1 for odd");

        uint8 cpuNumber = random();
        bool isEven = (number + cpuNumber) % 2 == 0;
        string memory message = string.concat("Player choose ",
            evenOrOdd,
            " and plays ",
            Strings.toString(number),
            " CPU plays ", Strings.toString(cpuNumber));

        if(isEven && compare(evenOrOdd, "EVEN")) {
            return string.concat(message, " Player won.");
        } else if (!isEven && compare(evenOrOdd, "ODD")) {
            return string.concat(message, " Player won.");
        } else {
            return string.concat(message, " CPU won.");
        }
    }
}

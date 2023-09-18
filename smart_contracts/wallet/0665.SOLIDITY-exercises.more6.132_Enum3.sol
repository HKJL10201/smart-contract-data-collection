//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract EnumExample {

    enum Hamburgers {CHILDREN, SMALL, MEDIUM, BIG}

    Hamburgers public myChoice;

    function setValue1() external {
        myChoice = Hamburgers.MEDIUM;
    }

    function setValue2() external {
        myChoice = Hamburgers(2);
    }

    function getEnum1() external view returns(Hamburgers) {
        return myChoice;
    }

    function getEnum2() external pure returns(Hamburgers) {
        return Hamburgers(0);
    }

    function getEnum3() external pure returns(Hamburgers) {
        return Hamburgers.CHILDREN;
    }

    function getEnum4() external view returns(uint) {
        return uint(myChoice) + 5;
    }

    Hamburgers[] public myArray = [Hamburgers(1), Hamburgers.BIG];
}
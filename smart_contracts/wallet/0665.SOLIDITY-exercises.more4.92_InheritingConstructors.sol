//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

/*Multi Inheritance constructor call can only be done if constructors are using parameters*/

contract A {
    string public myWord;
    constructor(string memory _word) {
        myWord = _word;
    }
}

contract B {
    uint public myNumber;
    constructor(uint _number) {
        myNumber = _number;
    }
}
// WAY 1: static input
contract C is A("Milky coffee"), B(9999999){

}

//WAY-2 :  dynamic input
// pay attention, there is no comma between A(x) and B(y)
contract D is A, B {
    constructor(string memory x, uint y) A(x) B(y) {

    }
}
//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract Counter {
    uint myNumber = 5;

    function addNumber(uint newNumber) external view returns(uint) {
        return myNumber+newNumber;
    }

    //Here return statement doesnt have any effect. It doesnt return.
    //But weirdly, it doesnt give error also. So, I left return statement
    // intentionally to not forget this.
    function addNumber2(uint newNumber2) external returns(uint) {
        myNumber = myNumber+newNumber2;
        return myNumber;
    }
}
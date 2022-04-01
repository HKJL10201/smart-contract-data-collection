//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract ConversionTest{
    int8 myNumber1 = -3;

    uint8 myNumber2 = uint8(myNumber1);

    function getNumber() external view returns(uint) {
        return myNumber2;
    }
}
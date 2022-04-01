//SPDX-Licence-Identifier: MIT

pragma solidity >= 0.8.7;

contract LengthVariable {
    function checkNumber(uint _number) external pure returns(uint) {
        if(_number > 100) {
            return _number + 1;
        } else {
            return _number + 15;
        }
    }

    function checkWord2(string memory _word) external pure returns(string memory) {
        return bytes(_word).length > 8 ? "long word" : "short word";
    }
}
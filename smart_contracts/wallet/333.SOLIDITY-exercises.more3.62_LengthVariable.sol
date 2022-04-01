//SPDX-Licence-Identifier: MIT

pragma solidity >= 0.8.7;

contract LengthVariable {
    function checkWord(string memory _word) external pure returns(string memory) {
        if(bytes(_word).length > 8 ) {
            return "long word";
        } else {
            return "it is just fine";
        }
    }

    function checkWord2(string memory _word) external pure returns(uint) {
        if(bytes(_word).length > 8 ) {
            return bytes(_word).length;
        } else {
            return bytes(_word).length + 222;
        }
    }
}
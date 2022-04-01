//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract stringComparison {

    function compare1(string memory _word) public pure returns(string memory) {
        if(keccak256(bytes(_word)) == keccak256(bytes("Hello"))) {
            return "You have inserted the right word";
        } else {
            return "Wrong word. You should have said Hello. with H capital";
        }
    }

    function compare2(string memory _word) public pure returns(string memory) {
        if (keccak256(abi.encodePacked(_word)) == keccak256(abi.encodePacked("hello"))) {
            return "You have inserted the right word";
        } else {
            return "Wrong word. You should have said Hello. with H capital";
        }
    }

    function compare3(bytes memory _word) public pure returns(string memory) {
        if (keccak256(_word) == keccak256("hello")) {
            return "You have inserted the right word";
        } else {
            return "Wrong word. You should have said Hello. with H capital";
        }
    }

    function getHash(string memory _word) external pure returns(bytes memory){
        return abi.encodePacked(_word);
    }
    function getHash2(string memory _word) external pure returns(bytes memory){
        return bytes(_word);
    }
    function getHash3(uint _word) external pure returns(bytes32){
        return bytes32(_word);
    }
    function getHash4(string memory _word) external pure returns(bytes32){
        return keccak256(bytes(_word));
    }


}
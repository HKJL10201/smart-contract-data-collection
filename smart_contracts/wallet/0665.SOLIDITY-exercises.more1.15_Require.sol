pragma solidity >=0.8.7;

contract Require{

    function checkInput(uint _input) public pure returns(string memory){
        require(_input >= 0, "invalid uint8");
        require(_input <= 255, "invalid uint8");
        return "Input is Uint8";
    }
     
    // Defining function to use require statement
    function Odd(uint _input) public pure returns(bool){
        require(_input % 2 != 0);
        return true;
    }

    function writeHello(string memory _word) public pure returns(bool) {
        require(keccak256(bytes(_word)) == keccak256(bytes("Hello")));
        return true;
    }
}
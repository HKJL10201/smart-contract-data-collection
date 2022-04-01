pragma solidity >=0.8.7;

contract RandomNumber {
    uint public firstNumber = 0;
    
    function createRandomNumber() public {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, firstNumber))) % 100;
        firstNumber = randomNumber;
    }
}

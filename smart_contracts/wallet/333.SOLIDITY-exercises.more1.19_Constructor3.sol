pragma solidity >=0.8.7;

contract RandomConstructor {

    uint public myNumber1;
    uint public myNumber2;
    
    constructor() {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty)));
        myNumber2 = randomNumber;
    }
    
    function getDifficulty() public {
        myNumber1 = block.difficulty;
    }

}
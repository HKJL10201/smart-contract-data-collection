pragma solidity ^0.4.8;

contract Lottery {
    
    
    enum LotteryState { Accepting, Finished }
    LotteryState state; 
    address owner;
    constructor() public {
        owner = msg.sender;
        state = LotteryState.Accepting;
    }

    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%8);
    }

    function deterWinner() public returns (uint) {
        state = LotteryState.Finished;
        uint winningNumber = random();
        return winningNumber;
    }
}
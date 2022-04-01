pragma solidity 0.4.25;

contract Dice{
    address public player1;
    address public player2;
    
    uint256 public player1Escrow;
    uint256 public player2Escrow;

    constructor() public payable{
        require(msg.value > 0);
        player1 = msg.sender;
        player1Escrow = msg.value;
    }

    function setupPlayer2() public payable{
        require(msg.value > 0);
        player2 = msg.sender;
        player2Escrow = msg.value;
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract lottery{
    // create players and the manager for the lottery
    address payable [] public players;
    address public manager;

    constructor(){
        manager = msg.sender;
    }

    // The function below will enable the contract accept Ether and also register every player who sends ETH
    receive() external payable{
        require(msg.value == 0.1 ether, "Invalid Amount, Deposit 0.1 Ether");
        players.push(payable(msg.sender));
    }

    // Check balance of the contract wallet
    function checkBalance() public view returns(uint){
        require(msg.sender == manager, "Access Deny");
        return address(this).balance;
    }

    // Create Random Number
    function randomNumber() public view returns(uint){
      return uint (keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    // Picked Winner
    function pickedWinner() public{
        require(msg.sender == manager);
        require(players.length >= 3);

        uint r = randomNumber();
        address payable winner;

        uint index = r % players.length;
        winner = players[index];

        winner.transfer(checkBalance());
        players = new address payable[](0);
        

    }

}
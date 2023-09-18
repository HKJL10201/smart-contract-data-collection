//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Lottery{

    address[] public players; // this is made address type because it will store address
    address public manager;
    
    constructor(){
        manager = msg.sender;  // msg.sender is global variable through which we r transferring address of this contract to manager
                               // msg.sender is the address that has called or initiated a function or created a transaction
    }


    function enterInLottery() public payable {
    require(msg.value == 0.1 ether, "Please send exactly 0.1 ether"); // Require correct payment amount
    players.push(msg.sender); // Add player to the array
  }

  function getPlayers() public view returns (address[] memory) {
    return players; // Return the array of players in order
  }

    function getBalance() public view returns(uint){
        require(msg.sender == manager,"You are not the manager");
        return address(this).balance;
    }

    //to get the balance of a particular address
    function getBalanceAddr(address payable player) public view returns (uint) {
    return player.balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }


    function pickWinner() public{
        require(msg.sender == manager,"Only Manager can pick the Winner");
        require (players.length >= 3,"Cannot pick a winner with less than 3 participants");

        uint r = random();
        address payable winner;
        uint index = r % players.length;

        winner = payable(players[index]);
        winner.transfer(getBalance());
        players = new address payable[](0);  // this line is written b/c once the winner is selected dynamic array become blank and lottery system again has to start
    }
    }

    




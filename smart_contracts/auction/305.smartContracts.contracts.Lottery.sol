// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor(){
        manager = msg.sender;
        players.push(payable(msg.sender));
    }

    receive() external payable{
        require(msg.value != 0.001 ether, "wrong amount");
        require(msg.sender != manager, "manager cannot enter the lottery");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint){
        require(msg.sender == manager, "sender is not the manager");
        return address(this).balance;
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager, "Caller is not the manager");
        require(players.length >= 3, "not enough players");

        uint r = random();
        address payable winner;
        uint index = r % players.length;
        winner = players[index];
        
        winner.transfer(getBalance());
        players = new address payable[](0); // resetting the lottery
    }
}
//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {

    //declaring the players and manager var
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    //making the receive to allow players to join
    receive () payable external {
        //require .1 ETH
        require(msg.value == 100000000000000000);
        //adding player to players array
        players.push(payable(msg.sender));
    }

    //modifier to require manager
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    //returning the contracts balance
    function getBalance() public view onlyManager returns(uint) {
        return address(this).balance;
    }

    //function to get random int
    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    //function to pick winner
    function pickWinner() public onlyManager {
        require(players.length > 3);
        //get random int
        uint r = random();
        address payable winner;
        //getting a random index
        uint index = r % players.length;
        //setting winner
        winner = players[index];
        //transfering the bal to winner
        winner.transfer(getBalance());
        //resetting players for next round
        players = new address payable[](0);
    }
}
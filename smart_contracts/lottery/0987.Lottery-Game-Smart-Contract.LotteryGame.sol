//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 <0.9.0;

contract Lottery{
    address public manager;
    address payable[] public players;

    constructor(){
        manager=msg.sender;
    }

    receive () payable external {
        require(msg.value == 1 ether, "Price should be equal to 1 Ether to participate");
        players.push(payable(msg.sender));
    }

    function getBalance() view public returns(uint){
        require(msg.sender == manager, "Only Manager can view the Balance");
        return address(this).balance;
    }

    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp, players.length)));
    }

    function pickWinner () public {
        require(msg.sender == manager , "Only Manager can pick the winner");
        require(players.length >= 3 , "Players should be minimum 3");
        uint r = random();
        address payable winner;
        uint index = r % players.length;
        winner = players[index];
        winner.transfer(getBalance());
    }
}
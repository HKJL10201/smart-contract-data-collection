// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Lottery{
    address payable[] public players;
    address manager;
    address payable public winner;

    constructor(){
        manager=msg.sender;
    }
    receive() external payable{ //receive is a special type of function.
        require(msg.value==0.1 ether, "Please pay 0.1 ether only");
        players.push(payable(msg.sender));
    }
    function getBalance() public view returns(uint){
        require(manager==msg.sender, "You are not the manager");
        return address(this).balance;
    }
    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length))); //This is not the best way to get a random number. We are inputting some value inside the keccak356 algorithm to get a hash and we are returning the uint of the hash
        //Without converting to uint hash is in bytes32 and it looks like this: bytes32: 0x7f0bf87cc66b247f9a81546e208d68007c62dc74efe15d966db71ad4266d0ce0
        //After converting to uint hash looks like this: uint256: 18713298875504598873105195902938350321358923188977311123451743723359499018279
    }
    function pickWinner() public{
        require(msg.sender==manager, "Only manager can start the lottery");
        require(players.length>=4, "Players are less than 4");

        uint r=random();
        uint index = r%players.length;
        winner=players[index];
        winner.transfer(getBalance());
        players = new address payable[](0); //Making the array empty using this syntax. This is to reset the lottery.
    }

    function allPlayers() public view returns(address payable[] memory){
        return players;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Lottery
{
    
    // state/storage variables
    address public owner;
    address payable[] public players;
    address[] public winners ;
    uint public lotteryId ;

    // constructor : runs after contract deployment only run once
    constructor()
    {
        owner = msg.sender ;
        lotteryId = 0 ;
    }

    // Enter Function : Enter the lottery

    // stores entire many into a contract address
    function enter() public payable 
    {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getPlayers() public view returns(address payable[] memory)
    {
        return players ;
    }

    function getBalance() public view returns(uint)
    {
        // WEI value
        return address(this).balance ;
    }

    function getLotteryId() public view returns(uint)
    {
        return lotteryId;
    }

    function getRandomNumber() public view returns(uint)
    {
        return uint( keccak256 (abi.encodePacked ( owner,block.timestamp  ) ) ) ;
    }

    function pickWinner() public 
    {
        require(msg.sender == owner );
        uint RandomIndex = getRandomNumber() % players.length ;
        players[RandomIndex].transfer (address(this). balance);
        winners.push(players[RandomIndex]);
        lotteryId++;

        // clearing players array
        players = new address payable[](0);
    }

    function getWinners() public view returns(address[] memory)
    {
        return winners ;
    }

}
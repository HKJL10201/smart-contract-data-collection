// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lottery{
    address public manager;
    address payable [] public players;
    address payable winner;
    bool public isComplete;
    bool public claimed;

    constructor(){
        manager = msg.sender;
        isComplete = false;
        claimed = false;
    }

    modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }

    function getManager()public view returns(address){
        return manager;
    }

    function getWinner() public onlyManager view returns(address) {
        return winner;
    }

    function enter() public payable{
        require(msg.value >= 0.001 ether);
        require(!isComplete);
        players.push(payable(msg.sender));
    }

    function pickWinner() public onlyManager{
        require(players.length>0);
        require(!isComplete);
        winner = players[randomNumber() % players.length];
        isComplete = true;
    }

    function randomNumber()private view returns(uint) {
         uint256 randomNo = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
         return randomNo;
    }

    function claimPrize() public{
        require(msg.sender == winner);
        require(isComplete);
        (bool success,)=winner.call{value: address(this).balance}("");
        require(success);
        claimed = true;
    }

    function getPlayers()public view returns(address payable[] memory){
         return players;
    }

    function status() public view returns(bool){
        return isComplete;
    }

}

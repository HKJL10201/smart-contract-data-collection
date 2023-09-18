pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Lottery {
    address payable[] public players;
    address public manager;
    uint index;
    
    constructor() {
        manager = msg.sender;
    }
    modifier onlyOwner() {
        require(manager == msg.sender);
        _;
    }

    function enter() public payable {
        require(msg.value >= 1 ether,"ethereum amount not enough");
        players.push(payable(msg.sender));
        
    }
    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp))) % players.length;
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function pickWinner() public onlyOwner {
        uint index = getRandomNumber() % players.length;
        players[index].transfer(address(this).balance);
     }

    function getWinner() public view returns (address, uint) {
        return (players[index], players[index].balance);
     }
    function getPlayers() public view returns (address payable[] memory) {
        return players;
     }
     function resetLottery() public onlyOwner {
          players = new address payable[](0);
     }

}
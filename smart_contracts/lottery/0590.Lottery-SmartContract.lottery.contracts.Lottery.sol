// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function pickWinner() public onlyManager {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        
        players = new address[](0);
    }

    function killContract() public onlyManager {
      selfdestruct(payable(manager));
    }
}
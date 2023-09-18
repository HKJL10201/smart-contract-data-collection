//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Lottery{
    address payable[] public players;
    address public manager;
    address payable public winner;
    uint256 constant MATIC_AMOUNT = 1e18;

    constructor(){
        manager = msg.sender;
    }

    function buyTickets() external payable {
        uint256 requiredAmount = MATIC_AMOUNT;
        require(msg.value == requiredAmount,"send 1 matic ether to buy ticket");
        players.push(payable(msg.sender));
    }

    function random() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager,"You are not the owner");
        require(players.length >= 3,"Not enough players");
        uint r = random();
        uint index = r%players.length;
        winner = players[index];
        winner.transfer(address(this).balance);
        players = new address payable[](0);
    }

    function allPlayers() public view returns(address payable[] memory) {
        return players;
    }
}
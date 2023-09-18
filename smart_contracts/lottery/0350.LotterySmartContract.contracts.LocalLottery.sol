// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract LocalLottery {
address public manager;
    address payable[] public players;
    address public lastWinner;

    event NewPlayerJoined(address indexed player);
    event LotteryWinner(address indexed winner, uint256 amount);

    // Modifier to restrict access to certain functions to the manager only
    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can perform this action.");
        _;
    }

    // Constructor to set the contract manager as the deployer of the contract
    constructor() {
        manager = msg.sender;
    }

    // Function for players to enter the lottery by sending Ether
    function enter() public payable {
        require(msg.value > 0, "You must send some ether to enter the lottery.");
        players.push(payable(msg.sender));
        emit NewPlayerJoined(msg.sender);
    }

    // Random number generator
    function getRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    // Function to pick a winner randomly and distribute the contract balance to the winner
    function pickWinner() public onlyManager {
        require(players.length > 0, "No players participated in the lottery.");

        uint256 index = getRandom() % players.length;
        address payable winner = players[index];
        uint256 contractBalance = address(this).balance;

        winner.transfer(contractBalance);
        lastWinner = winner;
        players = new address payable[](0);

        emit LotteryWinner(winner, contractBalance);
    }

    // Function to get the array of players who have entered the lottery
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    // Function to get the current balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

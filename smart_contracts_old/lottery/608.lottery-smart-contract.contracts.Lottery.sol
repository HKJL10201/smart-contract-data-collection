// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.sender != manager, 'Managers are not allowed to enter the lottery');
        require(msg.value > 100, 'Value must be greater than 100 wei!');
        
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted("You don't have a permission to pick a winner") {
        require(players.length > 0, 'No players registered yet!');

        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(address(this).balance);
        players = new address[](0);
    }

    function getPlayers() public view returns(address[] memory) {
        return players;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier restricted(string memory errorMsg) {
        require(msg.sender == manager, errorMsg);
        _;
    }
}
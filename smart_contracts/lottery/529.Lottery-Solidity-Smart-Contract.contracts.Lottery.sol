// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    modifier managerOnly() {
        require(msg.sender == manager, 'Only the manager can call this function');
        _;
    }

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .001 ether, 'Not enough ETH sent');
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public managerOnly {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
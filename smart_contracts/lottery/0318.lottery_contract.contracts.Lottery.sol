//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value == 0.5 ether, "you have to send .01 ether");
        players.push(payable(msg.sender));
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(manager, block.timestamp)));
    }

    function pickWinner() public onlyManager {
        uint256 index = getRandom() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }
}

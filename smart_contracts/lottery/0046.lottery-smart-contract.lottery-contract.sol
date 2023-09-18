pragma solidity ^0.5.0;

contract Lottery {
    address public manager;
    address payable[] players;
    address public lastWinner;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value >= 1 ether);
        players.push(msg.sender);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function selectWinner() public payable {
        require(msg.sender == manager);

        address payable winner = players[random() % players.length];
        uint prize = address(this).balance;

        lastWinner = winner;
        winner.transfer(prize);

        delete players;
    }

    function random() private view returns (uint) {
        return uint(keccak256(encodeData()));
    }

    function encodeData() private view returns (bytes memory) {
        return abi.encodePacked(block.difficulty, now, players.length);
    }
}
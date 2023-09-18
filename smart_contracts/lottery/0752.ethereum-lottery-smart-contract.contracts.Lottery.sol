pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    function getNumPlayers() public view returns (uint) {
        return players.length;
    }

    function enter() public payable {
        // automatically converted to appropriate amount of wei
        require(msg.value >= .01 ether, "Must send at least .01 ether");
        
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function pickWinner() public {
        require(msg.sender == manager, "You must be the manager to do that.");
        require(players.length > 0, "No players have entered yet.");

        uint index = random() % players.length;
        players[index].transfer(address(this).balance);

        players = new address[](0);
    }
}
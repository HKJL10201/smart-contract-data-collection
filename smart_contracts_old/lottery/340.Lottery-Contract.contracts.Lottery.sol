// Lottery contract 
// People pay ether to participate
// Winner gets all the money 

pragma solidity ^0.4.17;

contract Lottery {
    // creator of the contract 
    address public manager;

    // dynamic array of possible players - 
    // automatically creates a method to push elements 
    address[] public players;

    constructor () public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "Not enough ether paid for player");
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        bytes32 output = keccak256(abi.encodePacked(block.difficulty, now, players));
        return uint(output);
    }

    function pickWinner() public restricted {
        require(players.length > 0, "No players to pick winner");

        uint winner = random() % players.length;

        // Sends all the ether to winner
        players[winner].transfer(address(this).balance);

        players = new address[](0);
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

    modifier restricted() {
        require(msg.sender == manager, "This method can only be accessed by the manager");
        _; // code in pickWinner added to _
    }
}

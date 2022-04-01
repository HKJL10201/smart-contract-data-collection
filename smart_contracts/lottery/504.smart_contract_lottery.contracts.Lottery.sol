pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    // Dynamic array of addresses
    address[] public players;
    
    function Lottery() public {
        // Manager is the one who created the contract
        manager = msg.sender;
    }
    
    function enter() public payable {
        // Require some eth to enter the lottery
        require(msg.value > .01 ether);
        // Add the player address to the array of players
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        // Return pseudo big random number
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        // Pick a winner base on their index in the array and the ramdom number
        uint index = random() % players.length;
        // Transfer the ETH to the winner
        players[index].transfer(this.balance);
        // Set dynamic array to 0 to reset the lottery
        players = new address[](0);
    }

    // modifier that retricted authorization to pick a winner    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Get all the players that are participating to the lottery    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}
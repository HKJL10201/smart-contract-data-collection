pragma solidity ^0.4.17;

contract Lottery {

    address public manager;    // "address" data type for storing addresses
    address[] public players; // dynamic arrays are initialized without a length in bracket

    // Lottery contract constructor function
    function Lottery() public {
        manager = msg.sender; // msg is a global variable with info about current txn
    }

    // Define primary functions enter() and pickWinner()

    // Enter a new player into the lottery
    // Reject transactions below minimum ether threshold
    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    // Manager can select a random player and send prize pool to them
    // Reset players array afterwards
    function pickWinner() public payable restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }

    // Define helper functions and modifiers

    // Generate a pseudo random number; solidity does not have rand num generator
    function random() private view returns (uint) {
        return uint( keccak256( block.difficulty, now, players ) );
    }

    // Fetch players array, the auto-generated get function can only access a single index
    function getPlayers() public view returns (address[]) {
        return players;
    }

    // Only the manager can call a restricted function
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}

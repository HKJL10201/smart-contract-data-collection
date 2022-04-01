pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;


    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    // Since Solidity has not a random int generator,
    // we create our own function for doing so using long (32+ digits)
    // number sequences and the modulo % operator

    function random() public view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    // Use modifer from below in function
    function pickWinner() public restricted {

        uint index = random() % players.length;
        // In-built transfer function to send all money
        // from lottery contract to player
        players[index].transfer(this.balance);
        players = new address[](0);
    }

    // Make use of Solidity's modifier method to avoid repetition
    modifier restricted() {
        // Ensure the participant awarding the ether is the manager
        require(msg.sender == manager);
        _;
    }

    // Return list of players
    function getPlayers() public view returns (address[]) {
        return players;
    }
}

pragma solidity ^0.4.17;

contract Lottery {
    address public admin;
    address[] public players;

    function Lottery() public {
        admin = msg.sender;
    }

    function enterDraw() public payable {
        require(msg.value > 0.01 ether);

        players.push(msg.sender);
    }

    // use the block difficulty, the current time, and the number of players to create a pseudo-random integer
    function randomNumber() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    modifier restricted() {
        require(msg.sender == admin);
        _;
    }

    function pickWinner() public restricted {
        uint index = randomNumber() % players.length;

        // transfer the entire ether balance from this contract instance to the selected player
        players[index].transfer(this.balance);

        // reset players array with a length of zero
        players = new address[](0);
    }
    
    function fetchPlayers() public view returns (address[]) {
        return players;
    }
}

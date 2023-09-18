pragma solidity >0.4.17;

contract Lottery {
    address public manager; // Manager of the contact. Only the manager can pick a winner
    address[] public players; // Array of players

    function Lottery() public {
        manager = msg.sender; // The manager of the contact is who created it
    }

    function enter() public payable {
        require(msg.value > .01 ether); // Need more than .01 ether to enter

        players.push(msg.sender); // Enter address on array of players
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public restricted {
        uint256 index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager); // Only the creator of the contract can pick a winner
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}

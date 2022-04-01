pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }

    modifier requireManager() {
        require(msg.sender == manager);
        _;
    }

    function enter() public payable {
        require(msg.value > 0.001 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint) {
        return uint(sha3(block.difficulty, now, players));
    }

    function pickWinner() public requireManager {
        uint winnerIndex = random() % players.length;
        players[winnerIndex].transfer(this.balance);
        players = new address[](0);
    }

    function getPlayers() public view returns(address[]) {
        return players;
    }
}

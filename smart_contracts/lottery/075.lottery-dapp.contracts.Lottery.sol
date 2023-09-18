pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address public winner;
    address[] public players;

    function Lottery() public {
        manager = msg.sender;
    }
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    function pickWinnerWithCommissions() public restricted {
        uint index = random() % players.length;
        winner = players[index];
        uint commission = this.balance * 1 / 10;
        uint winnerAmount = this.balance * 9 / 10;
        players[index].transfer(winnerAmount);
        winner.transfer(winnerAmount);
        players = new address[](0);
    }
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    function getPlayers() public view returns (address[]) {
        return players;
    }
}
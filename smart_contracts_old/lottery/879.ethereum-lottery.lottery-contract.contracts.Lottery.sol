pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public previousWinners;
    address[] public players;


    function Lottery() public {
        manager = msg.sender;
    }

    //add payable keyword when person needs to send eth
    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    //pseudo random number generator, not actually very random
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    //pick the winner
    function pickWinner() public restricted {
        uint index = random() % players.length;
        previousWinners.push(players[index]);
        var managerWinnings = (this.balance * 10) / 100;
        var playerWinnings = (this.balance * 90) / 100;
        manager.transfer(managerWinnings);
        players[index].transfer(playerWinnings);
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    //return array of addresses
    function getPlayers() public view returns (address[]) {
        return players;
    }

    function getPreviousWinners() public view returns (address[]) {
        return previousWinners;
    }
}

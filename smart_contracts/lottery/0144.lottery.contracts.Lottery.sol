pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;

    function Lottery() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

    function pickWinner() public restricted {        
        // pick winner index
        uint index = random() % players.length;
        // set winner
        lastWinner = players[index];
        // transfer all contract amount to winner
        players[index].transfer(this.balance);
        // reset the players
        players = new address[](0);
    }

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }

    modifier restricted() {
        // sender needs to be manager to run this code
        require(msg.sender == manager);
        _;
    }
}

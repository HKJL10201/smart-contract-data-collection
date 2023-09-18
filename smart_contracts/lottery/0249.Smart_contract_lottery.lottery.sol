pragma solidity ^0.4.17;

contract Lottery {
    address public chief;
    address[] public players;
    
    function Lottery() public {
        chief = msg.sender;
    }
    
    function enterContract() public payable {
        require(msg.sender != chief); // chief cannot participate
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function randomGenerator() private view returns (uint) {
        return uint(sha256(block.difficulty, now, players));
    }
    
    function chooseWinner() public {
        require(msg.sender == chief);
		uint index = randomGenerator() % players.length;
        address winner = players[index];
        winner.transfer(this.balance);
        players = new address[](0);
    }
    
       
    function getPlayers() public view returns (address[]) {
        return players;
    }
}

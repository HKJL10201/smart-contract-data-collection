pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public { 
        manager = msg.sender;
    }
    
    function join() public payable {
    	require(msg.value > 0.01 ether); // This will make sure account sends 0.01 ether when joining
        players.push(msg.sender);
    }

    function pickWinner() public managerOnly {
        uint256 winnerIndex = randomizer() % players.length;
        players[winnerIndex].transfer(this.balance); // Address object has a built in transfer method
        players = new address[](0);  // Reset the players to start another lottery round
    }

    function randomizer() private view returns (uint256) {
    	return uint256(keccak256(block.difficulty, now, players));
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

    modifier managerOnly {
        require(msg.sender == manager);
        _; // This will be replaced by the contents of the functions marked as managerOnly internally
    }

    
}
pragma solidity ^0.4.17;

contract Lottery{

	address public manager; // manager is Someone who creates the Contract
	address[] public players; // Dynamic Array of Addresses of the Current Players
	mapping(address => bool) isPlayer;
	address public lastWinner;	
	
	function Lottery() public {
        manager = msg.sender;
	}

	function enter() public payable {
		require( msg.value >= 0.01 ether );
		require(msg.sender != manager); // Only Non-Manager can enter to the Lottery.
		require( isPlayer[msg.sender] == false ); // One Player can only participate once in a Single Lottery Contract.
		players.push(msg.sender);
		isPlayer[msg.sender] = true;
	}

	function random() private restricted_manager_access view returns (uint) {
		return uint( sha3(block.difficulty, now, players) );
	}

	function pickWinner() public restricted_manager_access {
		require(players.length != 0);
		uint winner_index = random() % players.length;
		players[winner_index].transfer(this.balance); // Transferring The Total Contract's value to the Winners Account.
		lastWinner = players[winner_index];
		players = new address[](0);
	}

	function getPlayers() public view returns(address[]){
		return players;
	}

	modifier restricted_manager_access() {
		require(msg.sender == manager);
		_;
	}

}
	

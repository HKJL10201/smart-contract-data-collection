pragma solidity ^0.4.17;
 
contract Lottery {
 address public manager;
 address[] public players; 
 address public winner; 

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

	  function pickWinner() public restricted returns(address) {
		  	uint index = random() % players.length;
		  	setWinner(players[index]);
		  	players[index].transfer(this.balance);
		  	players = new address[](0);
	  }

	  function setWinner(address winner_picked) private {
	  	winner = winner_picked;
	  }

	  function getWinner() public view returns (address){
	  	return winner;
	  }

	  modifier restricted() {
		  	require(msg.sender == manager);
		  	_;

	  }

	  function getPlayers() public view returns (address[]) {
	  		return players;
	  }

}
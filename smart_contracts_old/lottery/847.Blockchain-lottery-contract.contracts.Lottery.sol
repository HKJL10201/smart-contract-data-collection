 pragma solidity ^0.4.0;

contract Lottery{
	address public manager;
	address[] public players;

//  Manager address
	function Lottery() public{
		manager = msg.sender;
	}

// players has to pay 0.01 ether and push them to players array
	function enter() public payable{
		require(msg.value > 0.01 ether);
		players.push(msg.sender);
	}


//  pick a random winner
	function random() private view returns (uint){
	 	return uint(sha3(block.difficulty,now,players));
	}

//pick winner which is restricted and only run by manager

	function pickWinner() public restricted{
		uint index = random()%players.length;
		players[index].transfer(this.balance);
		players	= new address[](0);

	}
//to specify the restriction to manager
	modifier restricted(){
		require(msg.sender == manager);
		_;
	}

//return all players
	function getPlayers() public view returns(address[]){
		return players;
	}
}

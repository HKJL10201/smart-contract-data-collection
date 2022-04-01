pragma solidity >=0.4.22 <0.6.0;

contract Lottery {

	address public manager;
	address payable[] public players; //only this can transfer amount

	constructor() public {
		manager = msg.sender;
	}

	modifier is_manager() {
		require(msg.sender == manager);
		_;
	}

	function enter_players() public payable {
		require(msg.value > 0.1 ether);
		players.push(msg.sender);
	}

	function random() private view returns(uint256) {
		return uint256(keccak256(abi.encodePacked(block.difficulty, now, players)));
	}

	function pickwinner() public is_manager payable {
		uint256 index = random() % players.length;
		uint256 wal_bal = address(this).balance;
		players[index].transfer(wal_bal);
		players = new address payable[](0);
	}

	function getplayers() external view returns(address payable[] memory) {
		return players;
	}
}
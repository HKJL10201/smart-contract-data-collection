pragma solidity ^0.8.11;
//SPDX-License-Identifier: GPL-3.0

/* To draw lots*/
contract TDL {

	uint64 public ticketPrize;
	uint public jackpot;
	uint public ticketsSold;
	uint public lotteryEndTime;
	address payable[] public players;
	address public owner;

	event LotteryWinnerSet(address accountAddress, uint jackpotAmount);

	constructor(uint _whenEnd, uint64 _ticketPrize) {
		// convert_to_days=12*60*60*_whenEnd
		lotteryEndTime = block.timestamp + _whenEnd;
		ticketPrize = _ticketPrize;
		owner=msg.sender;
	}

	receive() external payable {
		require (block.timestamp <= lotteryEndTime, "After lottery time");
		require (msg.value == ticketPrize, "It requires same amount as given in the constructor");
		players.push(payable(msg.sender));
		jackpot += msg.value;
		ticketsSold += 1;
	}

	function random() private view returns (uint) {
		return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
	}

	function getJackpot() public view returns (uint) {
		return address(this).balance;
	}

	function endLottery () public{
		require (players.length>1);
		require (block.timestamp > lotteryEndTime);
	 	uint index = random() % players.length;
		players[index].transfer(address(this).balance);
	 	emit LotteryWinnerSet(players[index], jackpot);
		delete players;
	}
}
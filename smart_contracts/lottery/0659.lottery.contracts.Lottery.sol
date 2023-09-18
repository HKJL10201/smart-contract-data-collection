pragma solidity ^0.4.4;


contract Lottery {
	event PrintWinnerIndex(uint winner_index);

	address[16] public members;
	address public winner;
	uint public memberCount = 0;
	bool public lotteryOpen = true;

	modifier lotteryIsOpen() {require(lotteryOpen); _;}
	modifier lotteryIsFinished() {require(!lotteryOpen); _;}

	function signForLottery() payable lotteryIsOpen public returns (bool) {
		require(memberCount <= 15);
		require(msg.value == 0.1 ether);
		require(isNewMember(msg.sender));

		members[memberCount] = msg.sender;
		memberCount++;

		return true;
	}

	function selectLotteryWinner() lotteryIsOpen public returns (address) {
		require(memberCount > 0);

		uint winnerIndex = uint(block.blockhash(block.number - 1)) % memberCount;
		winner = members[winnerIndex];
		lotteryOpen = false;

		PrintWinnerIndex(winnerIndex);
		return winner;
	}

	function isNewMember(address member) private constant returns (bool) {
		for(uint i = 0; i < memberCount; i++) {
			if (members[i] == member) {
				return false;
			}
		}
		return true;
	}

	function withdrawPrice() public lotteryIsFinished {
		require(msg.sender == winner);

		uint multiplier = memberCount;
		winner = address(0);
		lotteryOpen = true;
		memberCount = 0;
		//memberCount is equal to amount of deposited ether;
		msg.sender.transfer(multiplier * 0.1 ether);
	}


	function getMembers() public returns (address[16]) {
		return members;
	}
}

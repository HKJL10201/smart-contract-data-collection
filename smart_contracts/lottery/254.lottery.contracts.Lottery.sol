//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/*
	Develop by mosalut
*/
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

import "./Dai.sol";

contract Lottery is Ownable {
	// The orderNumber of round.
	uint128 private orderNumber;

	// The winning number of every round.
	mapping(uint128 => uint16) private winNumbers;

	// The timestamp near by the next round start block time.
	// And if set it before it comes, then means overwrite it.
	uint private timestamp;
	uint private lastBlockTimestamp;

	// Reward pools, the key is orderNumber.
	mapping(uint128 => uint) private pools;

	// the total stakes at the round draw.
	mapping(uint128 => uint) private totalStakes;

	// users' stakes to the last round of the user join in.
	mapping(address => uint) private stakes;

	// users' last orderNumber stake.
	mapping(address => uint128) private lastStakeOrderNumber;

	// users' last chip in number. 
	mapping(address => uint16) private chipInNumbers;

	// The winners of each round.
	mapping(uint128 => address[]) private winners;
	mapping(uint128 => uint128) private winnerPoints;

	// If inRound is true, it's not allow create a new round.
	bool private inRound;

	// send the updated timestamp of the next round notice message to user.
	event CreateRound(uint timestamp);

	// reward message.
	event Reward(uint128, address, uint);

	Dai private dai;
	/*
		@mosalut
		daiAddr: DAI owner address. recieve fee and send reward.
	*/
	constructor(address daiAddr) {
		// The ERC20 contract DAI should have been approved to this contract by migrating.
		dai = Dai(daiAddr);
		lastBlockTimestamp = block.timestamp;
	}

	/*
		@mosalut
		Create one round.
		Set the timestamp through arg0
	*/
	function createRound(uint _timestamp) external onlyOwner {
		require(block.timestamp >= timestamp, "createRound: In a round now");
		require(_timestamp > block.timestamp, "createRound: Each round shound at least have one 5 minute for the users to ready 1");
		require(_timestamp - block.timestamp > 300, "createRound: Each round shound at least have one 5 minute for the users to ready 2");

		orderNumber++;
		winNumbers[orderNumber] = uint16(timestamp * _timestamp % 10000);

		timestamp = _timestamp;

		inRound = true;
		emit CreateRound(_timestamp);
	}

	/*
		@mosalut
		chip in a round.
	*/
	function chipIn(uint stake, uint16 numbers) external {
		// Compute the reward of the last round of user join in.
		// Withdraw and clean it.

		// stake * 5, 1 stake cost 5DAI
		require(stake > 0, "chipIn: stake should > 0!");
		require(dai.balanceOf(msg.sender) >= stake * 5, "chipIn: You've not enough DAI!");
		require(numbers < 10000, "chipIn: Number should less than 10000!");

		// when block.timestamp > timestamp means the newest round runing over,
		// then set inRound to false;
		// the condition inRound to ensure only change the inRound state once in each call.
		if(inRound && block.timestamp >= timestamp) {
			inRound = false;
		}

		// stake == 0 means the user hasn't join any round after last computing untill now.
		if(stakes[msg.sender] != 0) {
			uint128 _orderNumber = lastStakeOrderNumber[msg.sender];

			// if the user's stakes is belong to the newest round and round is runing,
			// this control flow won't excute.
			if(_orderNumber != orderNumber || !inRound) {
				// if win
				if(chipInNumbers[msg.sender] == winNumbers[_orderNumber]) {
					winnerPoints[_orderNumber]++;
					winners[_orderNumber].push(msg.sender);

					uint winStakes = countWinStakes(_orderNumber);
					// 5e18 = 1e18 * 5, cause 1 stake cost 5 DAI.
					uint rewardWithFee = totalStakes[_orderNumber] * 5e18 * stakes[msg.sender] / winStakes;
					uint reward = rewardWithFee * 80 / 100;

					
					pools[_orderNumber] -= rewardWithFee;

					// Because fee account is the same as reward account
					// so needn't recieve fee after below oparation.
					dai.transfer(msg.sender, reward);

					emit Reward(_orderNumber, msg.sender, reward);
				}
			}
		}	

		// update the stakes of the user.
		stakes[msg.sender] = stake;

		// update the last round the user join in number.
		lastStakeOrderNumber[msg.sender] = orderNumber;

		// update the user's chip in number.
		chipInNumbers[msg.sender] = numbers;

		// update the totalStakes of order number.
		totalStakes[orderNumber] += stake;

		// update the pool of order number.
		pools[orderNumber] += stake * 5e18;

		// chip in pay.
		dai.transferFrom(msg.sender, address(this), stake * 5e18);
	}

	/*
		@mosalut
		Count all winners' stake in a round.
	*/
	function countWinStakes(uint128 _orderNumber) view internal returns (uint) {
		uint winStakes;
		for(uint128 i = 0; i < winnerPoints[_orderNumber]; i++) {
			winStakes += stakes[winners[_orderNumber][i]];
		}

		return winStakes;
	}

	/*
		@mosalut
		History round info

		The frist return value is win number of this round.
		The Second return value is all winners account of this round. 
	*/
	function history(uint128 _orderNumber) external view returns (uint16, address[] memory) {
		require(_orderNumber != orderNumber || !inRound, "history: The round is runing!");
		return (winNumbers[_orderNumber], winners[_orderNumber]);
	}

	/*
		@mosalut
		History winner stakes by account.

		The second param is the account wants to query.
		The return value is the stakes the winner stake.
	*/
	function historyWinnerStakes(uint128 _orderNumber, address account) external view returns (uint) {
		for(uint128 i = 0; i < winnerPoints[_orderNumber]; i++) {
			if(account == winners[_orderNumber][i]) {
				return stakes[winners[_orderNumber][i]];
			}
		}
		return 0;
	}

	/*
		@mosalut
		Newest orderNumber

		The return value is newest order number; 
	*/
	function newest() external view returns (uint128) {
		return orderNumber;
	}

	/*
		@mosalut
		The user's in current round or last round info

		The first return value is current or last order number.
		The second return value is current or last timestamp,
		The third return value is win number.
		The forth return value is user's chip in number.
		When the forth return value is 0, means the user hadn't joined this round.

			chip in number = 849, the string is '0849'.
			chip in number = 49, the string is '0049'.
			chip in number = 9, the string is '0009'.

		The last return value is the user's staking quantity.
		When the last return value is 0, means the user hadn't joined this round.
	*/
	function lastStake(address account) external view returns (uint128, uint, uint16, uint16, uint) {
		if(lastStakeOrderNumber[account] == orderNumber) {
			return (orderNumber, timestamp, winNumbers[orderNumber], chipInNumbers[account], stakes[account]);
		}

		return (orderNumber, timestamp, winNumbers[orderNumber], 10000, 0);
	}

	/*
		@mosalut
		
		If inRound is true returns the newest order number.
		If inRound is false returns 0.
	*/
	function runingRound() view public returns(uint128) {
		if(inRound) {
			return orderNumber;
		}

		return 0;
	}

	/*
		@mosalut
		For debug, get win number.
		Release it, when testing.
	*/
	/*
	function debug() view public returns(uint16) {
		return winNumbers[orderNumber];
	}
	*/
}

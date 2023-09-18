pragma solidity ^0.4.23;

import "../contracts/LotteryOwnable.sol";

contract Lottery2 is LotteryOwnable {

	uint lotteryFee = 0.1 ether;
	mapping (uint8 => address) participants;
	mapping(address => bytes32) participantHash;
	address public owner;
	enum LotteryStage {phaseOne, phaseTwo, phaseThree};

	function participate1(bytes32 hash) external payable returns(address) {
		require(msg.value > lotteryFee);
		require(LotteryStage == phaseOne);
		participantHash[msg.sender] = hash;
		return(participants[address]);
	}

	function passToPhaseTwo() external onlyOwner {
		
	}
	function getBalance() public view returns (uint) { 
		uint contractBalance = address(this).balance;
		return(contractBalance);
	}

	function selectWinner() public view returns(address) {
		uint8 winner = 0; //will be changed later when the random is set
		address winnerAddress = participants[winner];
		return(winnerAddress);
	}

	function payTheReward() external onlyOwner returns(uint){
		address winnerAddress = selectWinner(); 
		uint currentBalance = getBalance();
		winnerAddress.transfer(address(this).balance);
		return (currentBalance);
	}
}
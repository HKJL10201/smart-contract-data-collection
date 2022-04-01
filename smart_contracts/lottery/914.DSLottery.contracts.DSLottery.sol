pragma solidity 0.5.12;

import "./Storage.sol";

contract DSLottery is Storage {
	// Only owner executable
	uint constant HOUSE_EDGE_PERCENT = 1;
	uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;
	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}

	constructor(uint currentTier, uint256 ticketPrice) public {
		_owner = msg.sender;
		_currentTier = currentTier;
		_tierStorage[_currentTier].ticketPrice = ticketPrice;
	}

	function setOwner() public payable{
		require(!_initialized);
		_owner = msg.sender;
	}

	// Activates a record that the current user participates in the lottery
	function participate() public payable {
		require(!(_tierStorage[_currentTier].participantsMapping[msg.sender] == true), "ALREADY_PLAYING");
		require(_tierStorage[_currentTier].ticketPrice > 0 wei, "TICKET_PRICE_NOT_SET");
		_tierStorage[_currentTier].participantsArray.push(msg.sender);
		_tierStorage[_currentTier].participantsMapping[msg.sender] = true;
		// If the value exceeds the ticket price becomes a donation to the prize pool
		_tierStorage[_currentTier].prize += _tierStorage[_currentTier].ticketPrice;
	}

	// Draws a winner at the end of the tier
	function drawWinner() public {
		// TODO implement oracle for generating random number
	}

	// Gets the amount of money that would be awarded to the winner
	function getPrizeAmount(uint tier) public view returns (uint256 prize){
		return _tierStorage[tier].prize;
	}

	// Reset the lottery and start the next tier
	function resetLottery() private {
		_currentTier++;
		// TODO implement functionality based on dates or perhaps consider block number
	}

	// Claim the prize
	function claimPrize(uint tier) public {
		Tier memory tierStruct = _tierStorage[tier];
		address winner = tierStruct.winner;
		require(tierStruct.claimed != true, "PRIZE_ALREADY_CLAIMED");
		require(winner != address(0), "WINNER_NOT_SELECTED");
		require(winner == msg.sender, "ONLY_WINNER_CAN_CLAIM_PRIZE");
		uint prize = getPrizeAmount(tier);
		uint houseEdge = prize * HOUSE_EDGE_PERCENT / 100;
		if (HOUSE_EDGE_MINIMUM_AMOUNT > houseEdge) {
			houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
		}

		assert(prize <= address(this).balance);

		uint256 amountToSend = getPrizeAmount(tier);
		assert(address(this).balance >= amountToSend);

		 _tierStorage[tier].claimed = true;

		msg.sender.transfer(amountToSend);
	}

	// Sets the minimal participation payment
	function setMinimumParticipationEther(uint256 amount) public onlyOwner {
		_uintStorage["minimumParticipationEther"] = amount;
	}

	// Gets the minimal participation price
	function getMinimumParticipationEther() public view returns (uint256 amount) {
		return _uintStorage["minimumParticipationEther"];
	}

	function getCurrentTicketPrice() public view returns (uint256 ticketPrice){
		return _tierStorage[_currentTier].ticketPrice;
	}

	function setCurrentTicketPrice(uint256 ticketPrice) public onlyOwner {
	require(_tierStorage[_currentTier].ticketPrice == 0 wei, "TICKET_PRICE_ALREADY_SET");
		_tierStorage[_currentTier].ticketPrice = ticketPrice;
	}
}

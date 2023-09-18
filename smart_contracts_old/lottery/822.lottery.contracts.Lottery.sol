pragma solidity 0.8.0;

// SPDX-License-Identifier: AGPL-3.0-only
// Author: https://github.com/ankurdaharwal

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RandomNumberGenerator.sol";

/// @title Lottery smart contract (consumes ChainLink VRF)
/// @author Ankur Daharwal (https://github.com/ankurdaharwal)
/// @notice Ownable Lottery smart contract that announces a lucky draw winner
/// @dev Uses a random number generator based on a VRFConsumerBase contract (https://docs.chain.link/docs/get-a-random-number/)
contract Lottery is Ownable {

	using EnumerableSet for EnumerableSet.AddressSet;
	using Address for address;
	using SafeMath for uint;

	enum LotteryState { Open, Closed, Finished }

	mapping(uint => EnumerableSet.AddressSet) entries;
	uint[] numbers;
	LotteryState public state;
	uint public numberOfEntries;
	uint public entryFee;
	uint public ownerCut;
	uint public winningNumber;
	address randomNumberGenerator;
	bytes32 randomNumberRequestId;

	/// @notice Lottery state event emitter
	/// @param newState possible states are: Open, Closed or Finished
	event LotteryStateChanged(LotteryState newState);
	/// @notice New entry event emitter
	/// @param player lottery participant's address
	/// @param number participant's lottery ticket number
	event NewEntry(address player, uint number);
	/// @notice Number request event emitter
	/// @param requestId request a random number using the RandomNumberGenerator
	event NumberRequested(bytes32 requestId);
	/// @notice Number drawn event emitter
	/// @param requestId unique request identifier
	/// @param winningNumber lucky draw winning ticket number
	event NumberDrawn(bytes32 requestId, uint winningNumber);

	// modifiers
	modifier isState(LotteryState _state) {
		require(state == _state, "Wrong state for this action");
		_;
	}

	modifier onlyRandomGenerator {
		require(msg.sender == randomNumberGenerator, "Must be called by a random number generator");
		_;
	}

	/// @dev Lottery contract constuctor
	/// @param _entryFee Participant's minimum entry fee
	/// @param _ownerCut Owner's fee for organizing the Lottery
	/// @param _randomNumberGenerator Random Number Generator contract address (Inherits VRF Consumer)
	constructor (uint _entryFee, uint _ownerCut, address _randomNumberGenerator) Ownable() {
		require(_entryFee > 0, "Entry fee must be greater than 0");
		require(_ownerCut < _entryFee, "Entry fee must be greater than owner cut");
		require(_randomNumberGenerator != address(0), "Random number generator must be valid address");
		require(_randomNumberGenerator.isContract(), "Random number generator must be a smart contract");
		entryFee = _entryFee;
		ownerCut = _ownerCut;
		randomNumberGenerator = _randomNumberGenerator;
		_changeState(LotteryState.Open);
	}

	/// @dev Participant submits a ticket number to participate in the lottery
	/// @param _number Participant's unique ticket number
	function submitNumber(uint _number) public payable isState(LotteryState.Open) {
		require(msg.value >= entryFee, "Minimum entry fee required");
		require(entries[_number].add(msg.sender), "Cannot submit the same number more than once");
		numbers.push(_number);
		numberOfEntries++;
		payable(owner()).transfer(ownerCut);
		emit NewEntry(msg.sender, _number);
	}

	/// @dev Draws a random number
	function drawNumber() public onlyOwner isState(LotteryState.Open) {
		_changeState(LotteryState.Closed);
		randomNumberRequestId = RandomNumberGenerator(randomNumberGenerator).request();
		emit NumberRequested(randomNumberRequestId);
	}

	/// @dev Rolls over the lottery
	function rollover() public onlyOwner isState(LotteryState.Finished) {
		//rollover new lottery
	}

	/// @dev Winning ticket number is drawn to announce the winner and lottery comes to an end
	/// @param _randomNumberRequestId Unique random number request identifier
	/// @param _randomNumber Winning ticket number can be drawn only by the RandomNumberGenerator contract
	function numberDrawn(bytes32 _randomNumberRequestId, uint _randomNumber) public onlyRandomGenerator isState(LotteryState.Closed) {
		if (_randomNumberRequestId == randomNumberRequestId) {
			winningNumber = _randomNumber;
			emit NumberDrawn(_randomNumberRequestId, _randomNumber);
			_payout(entries[_randomNumber]);
			_changeState(LotteryState.Finished);
		}
	}

	/// @dev Awards the lottery winners with the winning amounts
	/// @param winners Address set of all the winners of the lottery
	function _payout(EnumerableSet.AddressSet storage winners) private {
		uint balance = address(this).balance;
		for (uint index = 0; index < winners.length(); index++) {
			payable(winners.at(index)).transfer(balance.div(winners.length()));
		}
	}

	/// @dev Change the lottery's current state
	/// @param _newState Changes the state of the lottery
	function _changeState(LotteryState _newState) private {
		state = _newState;
		emit LotteryStateChanged(state);
	}
}

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./RandomNumberGenerator.sol";

contract Lottery is Ownable{

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

	event LotteryStateChanged(LotteryState newState);
	event NewEntry(address player, uint number);
	event NumberRequested(bytes32 requestId);
	event NumberDrawn(bytes32 requestId, uint winningNumber);

	// modifiers
	modifier isState(LotteryState _state) {
		require(state == _state, "Wrong state for this action");
		_;
	}

	modifier onlyRandomGenerator {
		require(msg.sender == randomNumberGenerator, "Must be correct generator");
		_;
	}

	//constructor
	constructor (uint _entryFee, uint _ownerCut, address _randomNumberGenerator) public Ownable() {
		require(_entryFee > 0, "Entry fee must be greater than 0");
		require(_ownerCut < _entryFee, "Entry fee must be greater than owner cut");
		require(_randomNumberGenerator != address(0), "Random number generator must be valid address");
		require(_randomNumberGenerator.isContract(), "Random number generator must be smart contract");
		entryFee = _entryFee;
		ownerCut = _ownerCut;
		randomNumberGenerator = _randomNumberGenerator;
		_changeState(LotteryState.Open);
	}

	//functions
	function submitNumber(uint _number) public payable isState(LotteryState.Open) {
		require(msg.value >= entryFee, "Minimum entry fee required");
		require(entries[_number].add(msg.sender), "Cannot submit the same number more than once");
		numbers.push(_number);
		numberOfEntries++;
		payable(owner()).transfer(ownerCut);
		emit NewEntry(msg.sender, _number);
	}

	function drawNumber(uint256 _seed) public onlyOwner isState(LotteryState.Open) {
		_changeState(LotteryState.Closed);
		randomNumberRequestId = RandomNumberGenerator(randomNumberGenerator).request(_seed);
		emit NumberRequested(randomNumberRequestId);
	}

	function rollover() public onlyOwner isState(LotteryState.Finished) {
		//rollover new lottery
	}

	function numberDrawn(bytes32 _randomNumberRequestId, uint _randomNumber) public onlyRandomGenerator isState(LotteryState.Closed) {
		if (_randomNumberRequestId == randomNumberRequestId) {
			winningNumber = _randomNumber;
			emit NumberDrawn(_randomNumberRequestId, _randomNumber);
			_payout(entries[_randomNumber]);
			_changeState(LotteryState.Finished);
		}
	}

	function _payout(EnumerableSet.AddressSet storage winners) private {
		uint balance = address(this).balance;
		for (uint index = 0; index < winners.length(); index++) {
			payable(winners.at(index)).transfer(balance.div(winners.length()));
		}
	}

	function _changeState(LotteryState _newState) private {
		state = _newState;
		emit LotteryStateChanged(state);
	}
}
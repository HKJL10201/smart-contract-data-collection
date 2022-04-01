pragma solidity ^0.4.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/*	Lottery that is drawn on a weekly basis 
*/
contract Lottery is Ownable {

	event PoolUpdated(address _by, uint newValue);
	event EntriesAcquired(address _by, uint numberEntries);

	struct Winner {
		address winningAddress;
		uint winningAmount;
	}

/* Properties */	
	// current drawing
	mapping (address => uint) public entries;
	address[] public allEntries;
	uint public totalPool;

	// tracking history
	uint public highestPool;
	Winner[] public pastWinners;

	// internal 
	uint private endTime;

	uint private LOTTO_DURATION = 30 seconds;
	uint private ENTRY_AMOUNT = 10 finney; // 0.01 ether

	modifier requireEntry() {
		require(msg.value >= ENTRY_AMOUNT); // require enough for at least one entry
		_;
	}

/* Initialization */
	function Lottery() public {
		_beginLottery();
	}

	// fallback function for sending ether directly to the contract
	function() public payable {
		enterLottery();
	}

/* Public Functions */
	// Enters into the lottery. 1 Finney = 1 entry
	// i.e. 1 Ether = 1000 entries
	function enterLottery() public payable requireEntry {
		totalPool += msg.value;
		uint numEntries = _numberOfEntries();
		_addEntriesFor(msg.sender, numEntries);
		EntriesAcquired(msg.sender, numEntries);
		PoolUpdated(msg.sender, totalPool);
	}

	function enterLotteryFromReferrer(address referrer) public payable requireEntry {
		require(referrer != 0x0);
		require(referrer != msg.sender);
		_addEntriesFor(referrer, uint(_numberOfEntries() / 2));
		enterLottery();
	}

	function endLottery() public onlyOwner {
		require(msg.sender == owner);
		require(endTime < now);

		var (winner, winnings) = _declareWinner();
		_transferWinnings(winner, winnings);
		_finalizeDrawing(winner, winnings);
		_drain();
	}

/* Getters */
	function getTotalPool() public constant returns (uint) {
		return totalPool;
	}

	function getAllEntries() public constant returns (address[]) {
		return allEntries;
	}

	function getEntryCountForAddress(address _address) public constant returns (uint) {
		return entries[_address];
	}

	function getRemainingTime() public constant returns (uint) {
		return endTime - now;
	}

	function getEndTime() public constant returns (uint) {
		return endTime;
	}

/* Private Helpers */
	function _addEntriesFor(address _address, uint numEntries) private {
		entries[_address] += numEntries;
		for (uint i = 0; i < numEntries; i++) {
			allEntries.push(_address);
		}
	}

	function _numberOfEntries() private view returns (uint) {
		return msg.value / ENTRY_AMOUNT;
	}

	function _declareWinner() private view returns (address winner, uint winnings) {
		winnings = totalPool - (totalPool / 20);
		uint winningIndex = uint(block.blockhash(block.number)) % allEntries.length;
		winner = allEntries[winningIndex];
		return (winner, winnings);
	}

	function _transferWinnings(address winner, uint winnings) private {
		require(winnings <= totalPool);
		winner.transfer(winnings);
		owner.transfer(totalPool - winnings);
	}

	function _finalizeDrawing(address winner, uint winnings) private {
		pastWinners.push(Winner(winner, winnings));
		if (winnings > highestPool) {
			highestPool = winnings;
		}
	}

	function _drain() private {
		totalPool = 0;
		delete allEntries;
		//delete entries;
	}

	function _beginLottery() private {
		endTime = now + LOTTO_DURATION;
	}
}
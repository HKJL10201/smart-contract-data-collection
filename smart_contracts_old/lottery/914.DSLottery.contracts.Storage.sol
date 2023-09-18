pragma solidity 0.5.12;

contract Storage {
	struct Tier {
		uint256 prize;
		address winner;
		bool claimed;
		address [] participantsArray;
		mapping (address => bool) participantsMapping;
		uint256 ticketPrice;
	}
	mapping (string => uint256) _uintStorage;
	mapping (string => address) _addressStorage;
	mapping (string => bool) _boolStorage;
	mapping (string => string) _stringStorage;
	mapping (string => bytes4) _bytesStorage;
	mapping (uint => Tier) _tierStorage;
	address public _owner;
	bool public _initialized;
	uint _currentTier;
	uint [] _previousTiers;
}
pragma solidity 0.7.5;

contract Ownable {
	mapping(address => bool) owners;
	uint minApprovals;
	
	modifier onlyOwners {
		require(owners[msg.sender] == true);
		_;
	}
	
	constructor(address[] memory _owners, uint _minApprovals) {
		for(uint i = 0; i < _owners.length; i++) {
			owners[_owners[i]] = true;
		}
		minApprovals = _minApprovals;
	}
}

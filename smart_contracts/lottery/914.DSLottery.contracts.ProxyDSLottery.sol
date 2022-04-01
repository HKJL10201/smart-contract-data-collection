pragma solidity 0.5.12;

import "./Storage.sol";

contract ProxyDSLottery is Storage {

	// Contract address
	address currentAddress;

	constructor(address _currentAddress) public {
		currentAddress = _currentAddress;
	}
	function upgrade(address _newAddress) public {
		currentAddress = _newAddress;
	}

	// Fallback function
	function () payable external {
		address implementation = currentAddress;
		require(currentAddress != address(0));
		bytes memory data = msg.data;

		// Delegates call to the contract address
		assembly {
			let result := delegatecall(gas, implementation, add(data, 0x20), mload(data), 0, 0)
			let size := returndatasize
			let ptr := mload(0x40)
			returndatacopy(ptr, 0, size)
			switch result
			case 0 {revert(ptr, size)}
			default {return(ptr, size)}
		}
	}
}
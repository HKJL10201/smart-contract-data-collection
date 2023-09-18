//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface ITest1{
	function changeWord(string memory _word) external;
}

contract Test2 {
	uint public myNumber = 5;

	function changeNumber(uint _newNumber) external {
		myNumber = _newNumber;
	}

	function call(address otherContract, string memory _new) external {
		ITest1(otherContract).changeWord(_new);
	}
}

//Here I am calling the changeWord function of the 141 and I am changing the state on the contract 141.
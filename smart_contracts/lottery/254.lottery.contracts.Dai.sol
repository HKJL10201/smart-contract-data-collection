//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dai is ERC20, Ownable {
	constructor () ERC20("DAI", "DAI") {}

	/*
		Mint tokens while deploy.
		The tokens quantity minted is the total supply.
	*/
	function mint(address account, uint amount) external onlyOwner {
		_mint(account, amount);
	}

	/*
		Destroy tokens and reduce the total supply
	*/
	function burn(address account, uint amount) external onlyOwner {
		_burn(account, amount);
	}
}

pragma solidity ^0.4.21;

import {IndexContract} from './IndexContract.sol';
// import {DIY} from './DIY.sol';

contract IndexContractFactory {
  address[] public indexContracts;

  constructor() public {
  }

  function get_index_contracts() external view returns (address[]) {
    return indexContracts;
  }

  function get_index_contract_count() external view returns (uint256) {
    return indexContracts.length;
  }

	function new_index_contract(
		address[] addresses, 
		uint256[] weights, 
		uint256 rebalanceInBlocks,
		address proxyAddress,
		address exchangeAddress,
		address WETHAddress,
		address diyindex
	) public payable returns (address) {
		IndexContract ic = new IndexContract(addresses, weights, rebalanceInBlocks, proxyAddress, exchangeAddress, WETHAddress, diyindex);
		indexContracts.push(ic);
		ic.transferOwnership(msg.sender);
		return ic;
//		DIY ic = new DIY(weights);
//		indexContracts.push(ic);
//		return ic;
	}
}

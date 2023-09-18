pragma solidity >=0.5.16;

import "./AggregatorV3Interface.sol";

contract AggregatorMock is AggregatorV3Interface {
	
	int256 ethPrice = 550e8;
	
	constructor() public {
		
	}
	
	function getPrice() public view returns (int256) {
		return ethPrice;
	}
	
	function setPrice(int256 _ethPrice) public {
		ethPrice = _ethPrice;
	}
	
	function decimals() external view returns (uint8 v) {
	}
	
	function description() external view returns (string memory v) {
		
	}
	
	function version() external view returns (uint256 v) {
		
	}

	function getRoundData(uint80 _roundId) external view returns (
		uint80 roundId,
		int256 answer,
		uint256 startedAt,
		uint256 updatedAt,
		uint80 answeredInRound
    ) {
	}
  
	function latestRoundData() external view returns (
		uint80 roundId,
		int256 answer,
		uint256 startedAt,
		uint256 updatedAt,
		uint80 answeredInRound
    ) {
		answer = ethPrice;
	}
	
}
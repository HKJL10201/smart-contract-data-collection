//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './PriceConverter.sol';

/**
 * set custom errors
 */
error notOwner();
error notEnoughTokens();
error callFailed();


contract FundMe {

  /**
   * Constant & Immutable are keywords for variables that can only be declared and updated once.
   */
  uint public constant minimumUSD = 50 * 1e18;
  address[] public funders;
  mapping (address => uint256) public addressToAmountFunded;
  using PriceConverter for uint256;
  address public immutable owner;
  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  modifier onlyOwner {
    if(msg.sender != owner) {
      revert notOwner();
    }
    _;
  }

  modifier insufficientToken() {
    if(msg.value < minimumUSD) {
      revert notEnoughTokens();
    }
    _;
  }
  
  function fund() public payable  insufficientToken {
    msg.value.getConversionRate(priceFeed);
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  /**
   * Loops through all the addresses in the funders array
   * reset amount funded for the looped addresses to 0
   * creates an empty funder array
   * Withdraws the funds 
   */
  function withdraw() public onlyOwner {
    for(uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }

    funders = new address[](0);

    (bool callSent, ) = payable(msg.sender).call{value: address(this).balance}("");
    if(!callSent){
      revert callFailed();
    }
   
  }

  /**SPECIAL FUNCTIONS
   * receive function is called when the calldata is empty
   * fallback function is called when the calldata is unrecognized
   */
  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}
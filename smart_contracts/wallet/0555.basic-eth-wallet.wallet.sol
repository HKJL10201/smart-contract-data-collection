// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BasicEthWallet {

    address payable public owner;
    uint minimumFundValue = 0;
    address[] public funders;
    mapping(address => uint256) addressToAmountFunded;
  
    constructor(){
        owner = payable(msg.sender);
    }

    function Pay() public payable {
    require(msg.value >= minimumFundValue, "Minimum amount not met");
    addressToAmountFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
    }

    function withdraw(uint _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function setMinimumFundValue(uint _minimumValue)public onlyOwner{   
        minimumFundValue=_minimumValue;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


}
//Allow Users deposit fund
//Allow a person that deployed contract to make withrawal
//set a mininum deposit value in usd 

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "./PriceConverter.sol";


error NotOwner();
contract FundMe {

    using PriceConverter for uint256;

    address[] public funders;

    mapping(address=>uint256) public addressToAmountMap;

    uint256 public mininumUsd = 50 * 1e18; //We can addd constant or immutable keyword after our public keyword inorder to reduce he cost of gas 
    address public owner; // We can aslo add constant or immutable keyword here

    constructor(){
        owner = msg.sender;
    }

    function fund() public payable{
        require(msg.value.getConversionRate() >= mininumUsd, "You didint send enough eth "); // Thats the value of 1 Eth
        funders.push(msg.sender);
        addressToAmountMap[msg.sender]= msg.value;
    }

    function withdraw() public onlyOwner {
        //(startingIndex, EndingIndex, Step)
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex]; // Get the address using using the fund index 
            addressToAmountMap[funder] = 0; // Use the address gotten from funders list to set the amount of adress in map to zero

        }

        funders = new address[](0);

        //transfer funds to  the address that deployed the contract 
        // bool sendSuccess = payable(msg.sender).transfer(address(this).balance); //using transfer method to send 
        // require(sendSuccess, "Send fail")

        // bool sendSuccess = payable(msg.sender).send(address(this).address); // using the send method to send fnds 

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}(""); // sing the call method to send funds 
        require(callSuccess, "called failed"); // \when call meyhods fails it retuns called failed 

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Failed Transaction, You must be owner");
        _;
        // We can use if(msg.sender != owner) {revert NotOwner();} // This alone can replace the require statement in our modifier and it is gas efficient

    }

}
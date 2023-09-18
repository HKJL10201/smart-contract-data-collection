//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Lottery {

    address[] public entries;
    uint public entryCostInWei;

    event EntryPurchased(address purchaser);

    constructor(uint _entryCostInWei) {
        entryCostInWei = _entryCostInWei;
    }

    function purchaseEntry() public payable {
        console.log("Purchase Entry called with %s value", msg.value);

        require(msg.value == entryCostInWei, "The purchase value must be exactly the entry cost");

        entries.push(msg.sender);  

        emit EntryPurchased(msg.sender);
    }
}
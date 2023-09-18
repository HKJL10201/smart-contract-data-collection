// SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.5.0;

contract Netflix{
    address payable netflixPubKey = 0x36e3bF69C0D369782396ED9e198b21dd2aC315EC;
    
    uint subscriptionCharges = 1 ether;

    function subscribeNetflix() external payable{
        require(msg.value == subscriptionCharges, "Subscription Failed: Not enough Ethers to subscribe to Netflix.");
        (bool sent,) = netflixPubKey.call.value(msg.value)("");
        require(sent, "Internal error occured, transaction failed. Please try again later.");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract bidder {
    string public name;
    uint public bidAmount = 20000;
    bool public eligible;
    uint constant minimumBid = 1000;

    function setName(string memory nm)  public {
        name = nm;
    }

    function setBidAmount(uint bidamt)  public {
        bidAmount = bidamt;
    }

    function determineEligibility()  public {
        if (bidAmount >= minimumBid) eligible = true;
        else eligible = false;
    }
}
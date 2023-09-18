// SPDX-License-Identifier: ISC
pragma solidity ^0.7.4;

import "./Auction.sol";

contract AuctionTest is Auction {
    // herança
    uint time;

    constructor (
        string memory contractName,
        uint targetAmountEth,
        uint durationInMin,
        address payable beneficiaryAddress
    )
        Auction(contractName, targetAmountEth, durationInMin, beneficiaryAddress)
        public
    {

    }

    function currentTime() override internal view returns(uint) {
        return time;
    }

    function setCurrentTime(uint newTime) public {
        time = newTime;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public offerPriceDecrement;

    // TODO: place your code here
    uint public auctionStartTime;
    uint public auctionEndTime;
    uint public reservedPrice;
    uint public currentPrice;
    bool seal;
    address public contractAddress;
    Timer public timer;

    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _offerPriceDecrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        offerPriceDecrement = _offerPriceDecrement;

        // TODO: place your code here
        timer = Timer(_timerAddress);
        auctionStartTime = timer.getTime();
        auctionEndTime = auctionStartTime + biddingPeriod;
        
    }


    function bid() public payable{
        // TODO: place your code here
        currentPrice = initialPrice - ((time() - auctionStartTime) * offerPriceDecrement);

        require(timer.getTime() < auctionEndTime);
        require(msg.value >= reservedPrice && msg.value >= currentPrice);
        
        winnerAddress = msg.sender;
        payable(msg.sender).transfer(address(this).balance - currentPrice);
    }

}

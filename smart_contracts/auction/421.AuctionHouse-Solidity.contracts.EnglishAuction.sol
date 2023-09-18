// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract EnglishAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public minimumPriceIncrement;

    // TODO: place your code here
    uint public bidStartTime;
    uint public bidDeadline;
    uint public bidEndTime;
    uint public currentPrice;
    address highestBidder;
    address contractAddress;
    uint public minBid;
    uint public previousBalance;
    Timer public timer;
    event print(address adr, uint value);

    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _minimumPriceIncrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;

        // TODO: place your code here
        timer = Timer (_timerAddress);
        bidStartTime = timer.getTime();
        bidDeadline = bidStartTime + biddingPeriod;
        currentPrice = initialPrice - minimumPriceIncrement;
        contractAddress = address(this);
        previousBalance = address(contractAddress).balance;
    }

    function bid() public payable{
        // TODO: place your code here
        //emit print(msg.sender, currentPrice);
        minBid = currentPrice + minimumPriceIncrement;
        require(timer.getTime() < bidStartTime + biddingPeriod);
        require(msg.value >= minBid);
        if(highestBidder != address(0))
            //refund_call = true;
            //refund_amount = address(contractAddress).balance - previousBalance;
            refund();
            //withdraw();
        currentPrice = msg.value;
        highestBidder = msg.sender;
        previousBalance = address(contractAddress).balance;
        
        bidStartTime = timer.getTime();
    }

    // Need to override the default implementation
    function getWinner() public override view returns (address winner){
        if(bidStartTime + biddingPeriod > timer.getTime())
            return address(0);
        else
            return highestBidder;
        // TODO: place your code here
    }

    

}

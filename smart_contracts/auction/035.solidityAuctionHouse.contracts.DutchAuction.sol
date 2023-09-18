pragma solidity ^0.4.18;
import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public offerPriceDecrement;
    uint public startTime;
    uint public endTime;
    uint public reservedPrice;

    event debug(uint256 currentPrice);
    event debugBig(uint256 bidValue);

    // constructor
    function DutchAuction(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _offerPriceDecrement) public
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        offerPriceDecrement = _offerPriceDecrement;
        startTime = time();
        endTime = time() + biddingPeriod;
        reservedPrice = initialPrice - biddingPeriod * offerPriceDecrement;

    }


    function bid() public payable{

        uint currentPrice = initialPrice - (time() - startTime) * offerPriceDecrement;
        require (  msg.value >= reservedPrice
                && msg.value >= currentPrice
                && time() < endTime
                && getWinner() == 0);

        winnerAddress = msg.sender;
        uint refund = this.balance - currentPrice;
        getWinner().transfer(refund);

    }

}

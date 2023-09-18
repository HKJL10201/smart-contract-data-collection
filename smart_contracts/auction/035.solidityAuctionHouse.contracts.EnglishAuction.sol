pragma solidity ^0.4.18;
import "./Auction.sol";

contract EnglishAuction is Auction {

    uint public initialPrice;
    uint public currentPrice;
    uint public biddingPeriod;
    uint public minimumPriceIncrement;
    uint public endTime;
    address currentWinner;



    // constructor
    function EnglishAuction(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _minimumPriceIncrement) public
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;
        currentPrice = initialPrice - minimumPriceIncrement;
        endTime = time() + biddingPeriod;
    }

    function bid() public payable{
      uint minimumAcceptedBid = currentPrice + minimumPriceIncrement;
      require(msg.value >= minimumAcceptedBid && time() < endTime);
      //refund outbid funds to previous bidder
      if(currentWinner != 0)
        currentWinner.transfer(currentPrice);

      currentPrice = msg.value;
      endTime = time() + biddingPeriod;
      currentWinner = msg.sender;

    }

    //TODO: place your code here
    //Need to override the default implementation
    function getWinner() public returns (address winner){
      // Do not decide who the winner is before aution ends
      return (time() < endTime) ? 0 : currentWinner;
    }
}

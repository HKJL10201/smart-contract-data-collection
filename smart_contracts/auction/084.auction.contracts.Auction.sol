pragma solidity ^0.5.0;

contract Auction {

    enum Outcome {
        NOT_FINISHED,
        NOT_SUCCESSFUL,
        SUCCESSFUL,
        SETTLED
    }

    Outcome public outcome;

    address payable public judgeAddress;
    address payable public sellerAddress;
    address payable public highestBidderAddress;

    uint public startTime;
    uint public currentTime;
    uint public highestBid;
    uint public initialPrice;
    uint public biddingPeriod;
    uint public minimumPriceIncrement;

    constructor(address payable _sellerAddress, address payable _judgeAddress, uint _initialPrice, uint _biddingPeriodSeconds, uint _minimumPriceIncrement) public {
        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriodSeconds;
        minimumPriceIncrement = _minimumPriceIncrement;

        startTime = 0;
        currentTime = 0;

        sellerAddress = _sellerAddress;
        judgeAddress = _judgeAddress;

        outcome = Outcome.NOT_FINISHED;
    }

    function bid() public payable {
        refreshOutcome();

        if(outcome != Outcome.NOT_FINISHED) {
            msg.sender.transfer(msg.value);
            revert("Auction has finished, cannot bid. Returning funds.");
        }

        if(msg.value < initialPrice) {
            msg.sender.transfer(msg.value);
            revert("Initial bid not higher than initial price. Returning funds to bidder...");
        }

        if(msg.value < highestBid + minimumPriceIncrement) {
            msg.sender.transfer(msg.value);
            revert("Minimum price increment not satisfied. Returning funds to bidder...");
        }

        if(highestBidderAddress != address(0)) {
            highestBidderAddress.transfer(address(this).balance - msg.value);
        }

        highestBid = msg.value;
        highestBidderAddress = msg.sender;
    }

    function settle() public {
        refreshOutcome();

        require(outcome == Outcome.SUCCESSFUL);
        require(msg.sender == judgeAddress);

        outcome = Outcome.SETTLED;

        sellerAddress.transfer(address(this).balance);
    }

    function refreshOutcome() internal {
        if(currentTime - startTime >= biddingPeriod * 1 seconds && outcome != Outcome.SETTLED) {
            if(highestBidderAddress != address(0)) {
                outcome = Outcome.SUCCESSFUL;
            } else {
                outcome = Outcome.NOT_SUCCESSFUL;
            }
        }
    }

    function setCurrentTime(uint _currentTime) public {
        require(_currentTime > currentTime, "Time can only be wind forward.");
        currentTime = _currentTime;

        refreshOutcome();
    }
}

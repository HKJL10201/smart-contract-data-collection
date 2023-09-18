// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Author: Bhargav Lalaji

contract Auction {
    address payable public beneficiary;
    uint public bidEndTime;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;

    bool ended;

    AggregatorV3Interface internal priceFeed;

    event BidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionEnd();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotEnded(uint timeToAuctionEnd);
    error AuctionEndCalled();

    constructor(uint biddingTime,address payable addressOfBeneficiary) {
        beneficiary = addressOfBeneficiary;
        bidEndTime = block.timestamp + biddingTime;
        priceFeed = AggregatorV3Interface(
               0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
            );
    }

    function bid() external payable {

        if (block.timestamp > bidEndTime)
            revert AuctionEnd();

        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit BidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }


    function auctionEnd() external {

        if (block.timestamp < bidEndTime)
            revert AuctionNotEnded(bidEndTime - block.timestamp);
        if (ended)
            revert AuctionEndCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

    }

    function transferBalance() external{
        require(msg.sender == beneficiary, "caller is not owner");

        if (!ended){
            revert AuctionNotEnded(bidEndTime - block.timestamp);
        }
        beneficiary.call{value: highestBid}("");
    }

    function getLatestPrice() public view returns (uint) {
            (
                ,
                /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
                ,
                ,

            ) = priceFeed.latestRoundData();
            return uint (price);
        }

    function priceInUsd() public view returns (uint){
        uint ValuePrice = getLatestPrice();
        uint priceInDollars = (ValuePrice * highestBid);
        return priceInDollars;
    }
}

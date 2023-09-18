// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Limited_Edition_Auction {
    address auctioneer; // The auctioneer who is selling the product
    uint256 public AuctionStartTime; //auction start time
    uint256 public AuctionEndTime; //aunction end time
    address public highestBidder; // address of highest bidder
    uint256 public highestBid; // value of highest bid
    product public productDetail; //show product detail

    struct product {
        //show deatil of product that is goint to be sold
        string name; // product name
        uint256 minimum_Price; // minimum betting price
    }


    error AuctionAlreadyEnded(); //show error when event ended
    error BidNotHighEnough(uint256 highestBid); //show error when bid is not high enough

    // set auctioneer and aunction time
    constructor(uint256 _auctionEndTime, address _auctioneer) {
        auctioneer = _auctioneer;
        AuctionEndTime = _auctionEndTime;
    }

    // show time remaining before the auction ended
    function RemainingTime() public view returns (uint256) {
        return (AuctionEndTime - (block.timestamp - AuctionStartTime));
    }

    //setting product detail
    function setProductDetail(string memory pName, uint256 _minimum_Price)
        public
    {
        require(msg.sender == auctioneer); // only auctioner can set deatil of the product
        productDetail = product(pName, _minimum_Price);

        AuctionStartTime = block.timestamp; //starting auction time

        highestBid = 0;
        highestBidder = 0x0000000000000000000000000000000000000000;
    }

    function bid() external payable {
        if ((block.timestamp - AuctionStartTime) > AuctionEndTime)
            // when bid is thrown and time is over error will be shown
            revert AuctionAlreadyEnded();

        if (msg.value <= highestBid)
            // when bid is not hign enough throw error
            revert BidNotHighEnough(highestBid);

        require(
            msg.value > productDetail.minimum_Price,
            "Bid Should be Higher than the minimum product price"
        ); // when bid value is less than miimum bedding price of product

        highestBidder = msg.sender; // setting highest bidder
        highestBid = msg.value; // setting highest bid value
    }

    //Winner Delclare Function
    function Winner() public view returns (address, uint256) {
        require(
            (block.timestamp - AuctionStartTime) > AuctionEndTime,
            "Time is remaining to End Auction"
        ); //winner only declare when auction is ended
        return (highestBidder, highestBid); // show winner details
    }
}

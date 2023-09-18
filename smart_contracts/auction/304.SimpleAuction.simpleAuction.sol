//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract openAuction {

    address payable public auctioneer; // the owner who is going to receive the higest amount
    uint public auctionEndTime;


    //This is from the bidding start
    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) public previousBidder; // to store the information of the last bidders and there bids. 

    bool public auctionEnded; //This will reflect the state of the auction.

    //event for a new high bid.
    event highestBidChanged(address bidder, uint amount);

    //event to announce the highest bidder at the end of time period.
    event winnerAnnounce(address winner, uint amount);

    //setting the address of the owner and the time till which the auction will run. 
    constructor(address payable _auctioneer, uint _auctionEndTime) {
        auctioneer = _auctioneer;
        auctionEndTime = _auctionEndTime + block.timestamp;        
    }

    //fuction to apply for the bid.
    function bid() public payable {

        if(block.timestamp >= auctionEndTime) revert("The auction has been already Ended! "); //The bid must be placed before the end time.

        if(highestBid > msg.value) revert("Please Try to make a big bid!"); //If anyone is placing a smaller bid value....

        if(highestBid != 0) previousBidder[highestBidder] += highestBid; //To store the bidder and the bid info in the mapping. 

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit highestBidChanged(msg.sender, msg.value); //emitting the event when high bid is placed.
    }

    //function for those bidders with less bids then the highest bids which are stored in  the mapping.
    function withdraw() external payable returns(bool) {
        uint amount = previousBidder[msg.sender];
        require(block.timestamp >= auctionEndTime, "The auction is not ended yet!");
        if(amount > 0) previousBidder[msg.sender] = 0; //So that one bidder can withdraw his money once. 

        if(!payable(msg.sender).send(amount)) //For those who did not placed any bid but still trying to withdraw money.
            {previousBidder[msg.sender] = amount;
            return false;
            }

        return true;    
    }


    //modifier for restricting others to end the auction.
    modifier onlyOwner(address owner) {
        require(msg.sender == owner, "You does not have Authority to End the bid! ");
        _;
    }
    
    //This function will only be executed by the owner or after a compleation of time.

    function endAuction() public onlyOwner(auctioneer) {

        if(auctionEnded) revert("The auction is already Ended! ");

        if(block.timestamp >= auctionEndTime) revert("The auction is Ended! ");
        
        auctionEnded = true;

        auctioneer.transfer(highestBid);
        emit winnerAnnounce(highestBidder, highestBid);
    }
}

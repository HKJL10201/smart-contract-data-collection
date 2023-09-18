//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleAuction {
    // @title Simple bid auction smart contract with no sealed bid feature, 
    // i.e. other users can see the bid price of the bidder and manipulate their bidding accordingly
    // @author Anshik Bansal

    // Auction parameters
    address public immutable beneficiary;
    uint public endtime;
    
    uint public highestBid;
    address public highestBidder;
    bool public hasEnded;

    // Amount withdrawable of previous bids
    mapping(address => uint) pendingReturns;

    // Events
    event NewBid(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    constructor (address _beneficiary, uint _durationMinutes) {
        beneficiary = _beneficiary;
        endtime = block.timestamp + _durationMinutes * 1 minutes;

    }

    // Update the bid, if the bidder puts higher bid amount
    function bid() public payable {
        require(block.timestamp < endtime, 'Auction Ended');
        require(msg.value > highestBid, 'Bid is too low');
        if (highestBid != 0){
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit NewBid(msg.sender, msg.value);
    }

    //Function to let user withdraw their pending amount
    function withdraw() external returns (uint amount) {

        amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    // Ending the auction if the end time duration has been passed
    function auctionEnd() external {
        // Check all conditions
        require(!hasEnded, 'Auction Already Ended!');
        require(block.timestamp >= endtime, 'Wait for the auction to end');

        // Apply all state changes
        hasEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        payable(beneficiary).transfer(highestBid);

    }

}
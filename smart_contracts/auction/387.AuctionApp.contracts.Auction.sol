//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract Auction {
    //state variables
    address payable public immutable auctioneer;
    address[] highestBidders;
    mapping(address => uint) public bids;
    uint public creationTime;
    // uint public immutable endTime;

    //events
    event highestBidEvent(address _highestBidder, uint _amount);
    event withdrawEvent(address _bidder, uint _amount);
    event AuctionEnd(address highestBidder, uint _amount);

    //modifiers
    modifier onlyBy() {
        require(msg.sender == auctioneer, "Only auctioneer can withdraw");
        _;
    }

    modifier onlyBefore(uint _time) {
        require(block.timestamp < _time, "Auction Ended");
        _;
    }

    constructor() {
        auctioneer = payable(msg.sender);
        creationTime = block.timestamp;
        // endTime= block.timestamp + 3 minutes;
    }

    function bid() external payable onlyBefore(creationTime + 3 minutes) {
        uint highestBid;

        for (uint i = 0; i < highestBidders.length; i++) {
            if (bids[highestBidders[i]] > highestBid) {
                highestBid = bids[highestBidders[i]];
            }
        }

        if (!(msg.value > highestBid))
            revert("Amount not higher than current bid");

        highestBidders.push(msg.sender);

        bids[msg.sender] = msg.value;

        emit highestBidEvent(msg.sender, msg.value);
    }

    function withdraw() external payable {
        //store bid in temp val and clear a variables;
        uint funds = bids[msg.sender];

        //clear from fund from map
        bids[msg.sender] = 0;

        //delete the address
        for (uint i = 0; i < highestBidders.length; i++) {
            if (highestBidders[i] == msg.sender) delete highestBidders[i];
        }

        (bool sent, ) = msg.sender.call{value: funds}("");

        if (!sent) revert("Error while sending ether");

        emit withdrawEvent(msg.sender, funds);
    }

    function endAuction() external payable onlyBy {
        if (block.timestamp < creationTime + 3 minutes)
            revert("Auction has notended");

        uint highestBid;
        address highestBidder;

        for (uint i = 0; i < highestBidders.length; i++) {
            if (bids[highestBidders[i]] > highestBid) {
                highestBid = bids[highestBidders[i]];
                highestBidder = highestBidders[i];
            }
        }
        uint funds = bids[highestBidder];

        // bids[msg.sender]=0;

        // //delete the address
        // for(uint i = 0;i<highestBidders.length;i++){

        //     if(highestBidders[i]==msg.sender)delete highestBidders[i];
        // }
        bids[msg.sender] = 0;

        (bool sent, ) = auctioneer.call{value: funds}("");

        if (!sent) revert("Error while sending ether");

        emit AuctionEnd(highestBidder, funds);

        //creationTime += 3 minutes;
    }
}

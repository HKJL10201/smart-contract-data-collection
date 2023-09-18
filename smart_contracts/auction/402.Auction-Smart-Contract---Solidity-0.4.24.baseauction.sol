pragma solidity ^0.4.24;

import './auction.sol';

// inheritance
contract BaseAuction is Auction {
    
    //state variable
    address public owner;
    
    // add modifier to set condition
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    // add event 
    event AuctionComplete(address winner, uint bid);
    event BidAccepted(address bidder, uint bid);
    
    constructor() public {
        owner = msg.sender;
    }
}

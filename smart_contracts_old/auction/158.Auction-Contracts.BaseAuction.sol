pragma solidity 0.5.11;

import "./Auction.sol";                     //importing auction.sol

contract BaseAuction is Auction {         // Inheritence
    
    address payable public owner;
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    event AuctionComplete(address winner, uint bid);
    event BidAccepted(address bidder , uint bid);
    
    constructor() public {
        owner=msg.sender;
    }
}

pragma solidity 0.4.19;


import "./Auction.sol";
contract BaseAuction is Auction{
    address public owner;
    
    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }
    
    event AuctionComplete(address winner, uint bid);
    
    function BaseAuction(){
        owner = msg.sender;
    }
    
    
}
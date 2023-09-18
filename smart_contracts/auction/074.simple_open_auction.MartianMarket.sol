pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./MartianAuction.sol";

contract MartianMarket is ERC721Full, Ownable {
    
    constructor() ERC721Full("MartianMarket", "MARS") public {}
    
    // @TODO: Setup counter for token_ids
    using Counters for Counters.Counter;
    
    Counters.Counter token_ids; // Keep track of unique token IDs
    
    // @TODO: Set foundation_address to the contract deployer (msg.sender) and make it payable
    address payable foundation_address = msg.sender;
    
    // @TODO: Create a mapping of uint (token_id) => MartianAuction
    mapping(uint => MartianAuction) public auctions;
    
    // @TODO: Create a modifier called landRegistered that accepts a uint token_id, and checks if the token exists using the
    // ERC721 _exists function. If the token does not exist, return a message like "Land not registered!"
    modifier landRegistered(uint token_id) {
        require(_exists(token_id), "Land not registered!");
        _;
    }
    
    function createAuction(uint token_id) public onlyOwner {
        // @TODO: Create a new MartianAuction contract in the mapping relating to the token_id
        // Pass the foundation_address to the MartianAuction constructor to set it as the beneficiary
        auctions[token_id] = new MartianAuction(foundation_address);
    }
    
    function registerLand(string memory uri) public onlyOwner {
        // @TODO: Increment the token_ids, and set a new id as token_ids.current
        token_ids.increment();
        uint token_id = token_ids.current();
        
        // @TODO: Mint a new token, setting the foundation as the owner, at the newly created id
        // @TODO: Use the _setTokenURI ERC721 function to set the token's URI by the id
        // @TODO: Call the createAuction function and pass the token's id
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
    }
    
    function endAuction(uint token_id) public onlyOwner landRegistered(token_id) {
        // @TODO: Fetch the MartianAuction from the token_id
        MartianAuction auction = auctions[token_id];
        
        // @TODO: Call the auction.end() function
        auction.auctionEnd();
        
        // @TODO: Call ERC721 safeTransferFrom, passing in owner() as the first param, auction.highestBidder() as the second, and token_id as the third
        // (Transfer from the owner of the token to the highest bidder of this auction, given this token_id)
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
    }
    
    function auctionEnded(uint token_id) public view returns(bool) {
        // @TODO: Fetch the MartianAuction relating to a given token_id, then return the value of auction.ended()
        MartianAuction auction = auctions[token_id];
        return auction.ended();
    }
    
    function highestBid(uint token_id) public view landRegistered(token_id) returns(uint){
        // @TODO: Return the highest bid of the MartianAuction relating to the given token_id
        MartianAuction auction = auctions[token_id];
        return auction.highestBid();
    }
    
    function pendingReturn(uint token_id, address sender) public view landRegistered(token_id) returns(uint) {
        // @TODO: Return the auction.pendingReturn() value of a given address and token_id
        MartianAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }
    
    function bid(uint token_id) public payable landRegistered(token_id) {
         // @TODO: Fetch the current MartianAuction relating to a given token_id
        MartianAuction auction = auctions[token_id];
        
        // @TODO: Call the auction.bid function using the auction.bid.value()() syntax
        // passing in msg.value in the first set of parenthesis to set the Ether being sent to the bid function,
        // and msg.sender in the second set of parenthesis to pass in the bidder parameter to the auction contract
        auction.bid.value(msg.value)(msg.sender);
    }
} 
//MartianMarket address: 0x7FBD6C0CB0e2Bd01770b02B5b27b83F0785aff6b

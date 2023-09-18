pragma solidity ^0.5.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";
import "./ArtAuction.sol";

contract ArtMarket is ERC721Full, Ownable {
    constructor() ERC721Full("ArtMarket", "ART") public {}
    
    // Setup counter for token_ids
    using Counters for Counters.Counter;
    Counters.Counter token_ids;
    
    // Set auction_address to the contract deployer (msg.sender aka auction house) and make it payable
    address payable auction_address = msg.sender;
    // Create payable address to for the beneficiary (aka the artist)
    address payable artist_address;
    
    // Set customer_return to false
    bool public customer_return;
    
    // Set customer_satisfied to false
    bool public customer_satisfied;
    
    // Create a mapping of uint (token_id) => ArtAuction
    mapping(uint => ArtAuction) public auctions;
    
    // Create a shipping event to attach shipping info to token 
    event Shipping(uint token_id, string shipping_uri);
    
    // Create a return event if customer is unsatisfied and needs to return art to artist, info will be recorded on token
    event ReturnArt(uint token_id, string return_uri);
    
    // artRegistered accepts a uint token_id, and checks if the token exists using the
    // ERC721 _exists function
    modifier artRegistered(uint token_id) {
        require(_exists(token_id), "Art not registered!");
        _;
    }
    
    // Creates a new ArtAuction contract in the mapping relating to the token_id
    // Passes the artist_address to the ArtAuction constructor to set it as the beneficiary
    function createAuction(uint token_id, address payable artist_address) public onlyOwner {
        auctions[token_id] = new ArtAuction(artist_address);
    }
    
    function registerArt(string memory uri, address payable artist_address) public payable onlyOwner returns (uint) {
        // Increment the token_ids, and set a new id as token_ids.current
        token_ids.increment();
        uint token_id = token_ids.current();
        // Mint a new token, setting the foundation as the owner, at the newly created id
        _mint(auction_address, token_id);
        // Use the _setTokenURI ERC721 function to set the token's URI by the id
        _setTokenURI(token_id, uri);
        // Call the createAuction function and pass the token's id
        createAuction(token_id, artist_address);
        return token_id;
    }
    
    // custSatisfaction function to enforce authenticity and customer satisfaction
    function custSatisfaction(bool answer, uint token_id) public {
        if (answer)
        {
            // If buyer answers true they are satisfied with their art upon arrival
            ArtAuction auction = auctions[token_id];
            require (now > auction.endTime(), "There is still time in the auction");
            require (msg.sender == auction.highestBidder(), "You are not the buyer!" );
            // 
            customer_satisfied = true;
        }
        else 
        {
            // If the buyer is not satisfied they must start their art return with the return_art function
            // Bidding restarts at 0ETH
            ArtAuction auction = auctions[token_id];
            require (msg.sender == auction.highestBidder(), "You are not the buyer!");
            require (customer_return, "No pending return exists");
            // Once return_art is initiated, the highest bid is returned to the buyer
            // Auction resets and bidding starts at 0ETH
            auction.resetAuction();
            auctions[token_id] = new ArtAuction(artist_address);
        }
        
    }
    
    function endAuction(uint token_id) public artRegistered(token_id) {
        // Fetch the ArtAuction from the token_id
        ArtAuction auction = auctions[token_id];
        // Call the auction.end() function
        auction.auctionEnd();
    }
    
    function transferToken(uint token_id) public onlyOwner artRegistered(token_id) {
        // Require that buyer has reported satisfied in the customer_satisfied function
        require (customer_satisfied, "Customer has not reported as satisfied");
        // Fetch the ArtAuction from the token_id
        ArtAuction auction = auctions[token_id];
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
        endAuction(token_id);
    }
         
    function auctionEnded(uint token_id) public view returns(bool) {
        // Fetch the ArtAuction relating to a given token_id, then return the value of auction.ended()
        ArtAuction auction = auctions[token_id];
        return auction.ended();
    }
    
    function highestBidder(uint token_id) public view artRegistered(token_id) returns(address) {
        // Return the highest bid of the ArtAuction relating to the given token_id
        ArtAuction auction = auctions[token_id];
        return auction.highestBidder();
    }
    
    function highestBid(uint token_id) public view artRegistered(token_id) returns(uint) {
        // Return the highest bid of the ArtAuction relating to the given token_id
        ArtAuction auction = auctions[token_id];
        return auction.highestBid();
    }
    
    function artistAddress(uint token_id) public view artRegistered(token_id) returns(address) {
        // Fetch the ArtAuction relating to a given token_id and return artist_address
        ArtAuction auction = auctions[token_id];
        return auction.beneficiary();
    }
    
    function pendingReturn(uint token_id, address sender) public view artRegistered(token_id) returns(uint) {
        // Return the auction.pendingReturn() value of a given address and token_id
        ArtAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }
    
    function bid(uint token_id) public payable artRegistered(token_id) {
        // Fetch the current ArtAuction relating to a given token_id
        ArtAuction auction = auctions[token_id];
        // Call the auction.bid function
        auction.bid.value(msg.value)(msg.sender);
    }
    
    function shipping(uint token_id, string memory shipping_uri) public {
        // Fetch the ArtAuction from the token_id
        ArtAuction auction = auctions[token_id];
        require(msg.sender == auction.beneficiary(), "You are not the artist!");
        // Attach shipping info to token
        emit Shipping(token_id, shipping_uri);
    }
    
    function return_art(uint token_id, string memory return_uri) public {
        // Fetch the ArtAuction from the token_id
        ArtAuction auction = auctions[token_id];
        require (now > auction.endTime(), "There is still time in the auction");
        require(msg.sender == auction.highestBidder(), "You are not the buyer!");
        customer_return = true;
        // Attach return shipping info to token
        emit ReturnArt(token_id, return_uri);
    }
    
}
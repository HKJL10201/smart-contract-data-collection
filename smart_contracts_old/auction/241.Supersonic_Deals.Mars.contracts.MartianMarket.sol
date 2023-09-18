pragma solidity >=0.4.21 <0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
/* OR */
//import '../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
//import '../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './MartianAuction.sol';

//https://columbia.bootcampcontent.com/columbia-bootcamp/CU-NYC-FIN-PT-12-2019-U-C/blob/master/22-DeFi/3/Activities/06-Stu_Building_Martian_Market/Solved/MartianMarket.sol

contract MartianMarket is ERC721Full, Ownable {

    constructor() ERC721Full("MartianMarket", "MARS") public {}

    using Counters for Counters.Counter;

    Counters.Counter tokenIds;

    // cast a payable address for the Martian Development Foundation to be the beneficiary in the auction
    // this contract is designed to have the owner of this contract (foundation) to pay for most of the function calls
    // (all but bid and withdraw)
    address payable foundationAddress = msg.sender;

    mapping(uint => MartianAuction) public auctions;

    function registerLand(string memory tokenURI) public payable onlyOwner {
        uint _id = totalSupply();
        _mint(msg.sender, _id);
        _setTokenURI(_id, tokenURI);
        createAuction(_id);
    }

    function createAuction(uint tokenId) public onlyOwner {
        // initiate new auctions
        auctions[tokenId] = new MartianAuction(foundationAddress);
    }

    function endAuction(uint tokenId) public onlyOwner {
        // Require existing tokenID to prevent lossing ether 
        require(_exists(tokenId), "Unregistered land. Please double check your token ID.");
        MartianAuction auction = getAuction(tokenId);
        // End auction and transfer land from the owner to verified highest bidder safely
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), tokenId);
    }

    function getAuction(uint tokenId) public view returns(MartianAuction auction) {
        // Pull information from createAuction(uint tokenID)
        return auctions[tokenId];
    }

    function auctionEnded(uint tokenId) public view returns(bool) {
       // Require existing tokenID to prevent lossing ether 
        require(_exists(tokenId), "Unregistered land. Please double check your token ID.");    
        MartianAuction auction = getAuction(tokenId);
        return auction.ended();
     }

    function highestBid(uint tokenId) public view returns(uint) {
       // Require existing tokenID to prevent lossing ether 
        require(_exists(tokenId), "Unregistered land. Please double check your token ID.");    
        MartianAuction auction = getAuction(tokenId);
        return auction.highestBid();
    }

    function pendingReturn(uint tokenId, address sender) public view returns(uint) {
       // Require existing tokenID to prevent lossing ether 
        require(_exists(tokenId), "Unregistered land. Please double check your token ID.");    
        MartianAuction auction = getAuction(tokenId);
        return auction.pendingReturn(sender);
     }

    function bid(uint tokenId) public payable {
       // Require existing tokenID to prevent lossing ether 
        require(_exists(tokenId), "Unregistered land. Please double check your token ID.");    
        MartianAuction auction = getAuction(tokenId);
        auction.bid.value(msg.value)(msg.sender);
    }

}

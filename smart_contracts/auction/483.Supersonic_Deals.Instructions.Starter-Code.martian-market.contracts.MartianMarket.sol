pragma solidity ^0.5.0;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
import '../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './MartianAuction.sol';

contract MartianMarket is ERC721Full, Ownable {
    constructor() ERC721Full("MartianMarket", "MARS") public {}

    // cast a payable address for the Martian Development Foundation to be the beneficiary in the auction
    // this contract is designed to have the owner of this contract (foundation) to pay for most of the function calls
    // (all but bid and withdraw)
    address payable foundationAddress = address(uint160(owner()));

    mapping(uint => MartianAuction) public auctions;

    function registerLand(string memory tokenURI) public payable onlyOwner {
        uint _id = totalSupply();
        _mint(msg.sender, _id);
        _setTokenURI(_id, tokenURI);
        createAuction(_id);
    }

    function createAuction(uint tokenId) public onlyOwner {
        // your code here...
    }

    function endAuction(uint tokenId) public onlyOwner {
        require(_exists(tokenId), "Land not registered!");
        MartianAuction auction = getAuction(tokenId);
        // your code here...
    }

    function getAuction(uint tokenId) public view returns(MartianAuction auction) {
        // your code here...
    }

    function auctionEnded(uint tokenId) public view returns(bool) {
        // your code here...
    }

    function highestBid(uint tokenId) public view returns(uint) {
        // your code here...
    }

    function pendingReturn(uint tokenId, address sender) public view returns(uint) {
        // your code here...
    }

    function bid(uint tokenId) public payable {
        // your code here...
    }

}

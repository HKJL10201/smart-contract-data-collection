// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./MintNFT.sol";

// creates interface which allows us to uses openzeppelin functions
interface IMintNFT {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _nftId
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function balanceOf(address _owner) external view returns (uint256);
}

contract NFTDutchAuction is Initializable {
    uint256 reservePrice;
    uint256 numBlocksAuctionOpen;
    uint256 offerPriceDecrement;
    uint256 initialPrice;
    address erc721TokenAddress;
    uint256 public nftTokenID;

    address seller;
    address public winner;

    uint256 blockStart;
    uint256 totalBids = 0;
    uint256 refundAmount;
    bool public isAuctionOpen = true;

    IMintNFT private mintNFT; // initializes interface to mintNFT

    constructor(
        address _erc721TokenAddress,
        uint256 _nftTokenID,
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement
    ) {
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        // sets the initial price to the equation below
        initialPrice =
            _reservePrice +
            _numBlocksAuctionOpen *
            _offerPriceDecrement;
        // assigning seller to the person who's currently connecting with the contract
        seller = msg.sender;
        // assigns the current block as the starting block
        blockStart = block.number;
        erc721TokenAddress = _erc721TokenAddress;
        nftTokenID = _nftTokenID;
    }

    /*
    function initialize(
        address _erc721TokenAddress,
        uint256 _nftTokenID,
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement
    ) public initializer {
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        // sets the initial price to the equation below
        initialPrice =
            _reservePrice +
            _numBlocksAuctionOpen *
            _offerPriceDecrement;
        // assigning seller to the person who's currently connecting with the contract
        seller = msg.sender;
        // assigns the current block as the starting block
        blockStart = block.number;
        erc721TokenAddress = _erc721TokenAddress;
        nftTokenID = _nftTokenID;
    }
*/
    // takes nft minting contracts address as parameter
    function setMintContractAddress(IMintNFT _mintNFT) public {
        mintNFT = _mintNFT;
    }

    function getCurrentPrice() public view returns (uint256) {
        return initialPrice - (block.number - blockStart) * offerPriceDecrement;
    }

    // bid function makes checks, accepts or rejects bids, and executes the wei transfer if accepted
    function bid() public payable returns (address) {
        require(isAuctionOpen, "Auction is closed"); // checks to make sure the auction is still open
        require(
            winner == address(0),
            "You just missed out! There is already a winner for this item"
        ); // check if there is a winner
        require(msg.sender != seller, "Owner cannot submit bid on own item"); // check if the owner bids on own item
        require(
            block.number - blockStart <= numBlocksAuctionOpen,
            "Auction has closed - total number of blocks the auction is open for have passed"
        ); // check if the duration of the auction has passed by seeing what block we're on
        require(
            address(this).balance > 0,
            "Your accounts balance is not greater than 0"
        ); // checks if the bidding address's balance is greater than 0
        require(
            msg.value >= getCurrentPrice(),
            "You have not sent sufficient funds"
        ); // check if the buyer has bid a sufficient amount
        require(nftTokenID >= 0, "The NFT token ID is less than 0"); // checks if the nft id is negative

        totalBids++; // increments totalBids by 1 every time a bid is entered

        require(totalBids > 0, "There must be at least one bid to finalize"); // checks if there is at least one bid on item

        winner = msg.sender; // assigns winner to address with first winning bid - finalize fn
        payable(seller).transfer(msg.value); // transfers wei from bidder to seller
        mintNFT.safeTransferFrom(seller, winner, nftTokenID); // transfer nft from seller to winner based on its id

        isAuctionOpen = false; // sets isAuctionOpen variable to false
        return winner;
    }

    // returns the sellers address
    function getSellerAddress() public view returns (address) {
        return seller;
    }

    // returns the reserve price
    function getReservePrice() public view returns (uint256) {
        return reservePrice;
    }

    // returns the number of blocks open auction is open for
    function getNumBlocksAuctionOpen() public view returns (uint256) {
        return numBlocksAuctionOpen;
    }

    // returns the price decrement
    function getPriceDecrement() public view returns (uint256) {
        return offerPriceDecrement;
    }

    function getWinner() public view returns (address) {
        require(winner == msg.sender, "You are the winner"); // checks if the winner variable is the winning address
        return winner;
    }

    function balanceOf(address) public view returns (uint256) {
        return address(this).balance;
    }
}

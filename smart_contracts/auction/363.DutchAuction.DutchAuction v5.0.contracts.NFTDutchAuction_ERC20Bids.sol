// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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

interface IMintERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool);
}

/*
interface IERC20Permit {
    function ERC20Permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 v,
        bytes32 r,
        bytes32 s
    ) external;
}
*/
contract NFTDutchAuction_ERC20Bids is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    uint256 reservePrice;
    uint256 numBlocksAuctionOpen;
    uint256 offerPriceDecrement;
    uint256 initialPrice;
    address erc721TokenAddress;
    uint256 public nftTokenID;

    address seller;
    address public winner;

    uint256 blockStart;
    uint256 totalBids;
    uint256 refundAmount;
    bool public isAuctionOpen;

    IMintNFT mintNFT; // initializes interface to mintNFT
    IMintERC20 mintERC20;

    address erc20TokenAddress;

    function initialize(
        address _erc20TokenAddress,
        address _erc721TokenAddress,
        uint256 _nftTokenID,
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

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
        erc20TokenAddress = _erc20TokenAddress;
        mintERC20 = IMintERC20(erc20TokenAddress);
        mintNFT = IMintNFT(erc721TokenAddress);
        totalBids = 0;
        isAuctionOpen = true;
    }

    function getCurrentPrice() public view returns (uint256) {
        return initialPrice - (block.number - blockStart) * offerPriceDecrement;
    }

    // bid function makes checks, accepts or rejects bids, and executes the wei transfer if accepted
    function bid(uint256 _bidAmount) public payable returns (address) {
        console.log(msg.sender, "bid", _bidAmount, "VToken");
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
        // require(
        //     address(this).balance > 0,
        //     "Your accounts balance is not greater than 0"
        // ); // checks if the bidding address's balance is greater than 0
        // require(
        //     msg.value >= getCurrentPrice(),
        //     "You have not sent sufficient funds"
        // ); // check if the buyer has bid a sufficient amount
        // require(nftTokenID >= 0, "The NFT token ID is less than 0"); // checks if the nft id is negative
        require(
            mintERC20.balanceOf(msg.sender) >= _bidAmount,
            "You have bid more tokens than you own"
        );

        totalBids++; // increments totalBids by 1 every time a bid is entered

        require(totalBids > 0, "There must be at least one bid to finalize"); // checks if there is at least one bid on item

        winner = msg.sender; // assigns winner to address with first winning bid - finalize fn
        // payable(seller).transfer(msg.value); // transfers wei from bidder to seller
        mintERC20.transferFrom(winner, seller, getCurrentPrice());
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

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract NFTDutchAuction {
    address payable public immutable owner;

    address public immutable erc721TokenAddress;
    uint256 public immutable nftTokenId;
    uint256 public immutable reservePrice;
    uint256 public immutable numBlocksAuctionOpen;
    uint256 public immutable offerPriceDecrement;

    IERC721 internal immutable nft;
    uint256 public immutable startBlock;
    uint256 public immutable initialPrice;
    address public winner;

    constructor(
        address _erc721TokenAddress,
        uint256 _nftTokenId,
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement
    ) {
        owner = payable(msg.sender);

        erc721TokenAddress = _erc721TokenAddress;
        nftTokenId = _nftTokenId;
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;

        nft = IERC721(_erc721TokenAddress);

        require(
            nft.ownerOf(_nftTokenId) == owner,
            "The NFT tokenId does not belong to the Auction's Owner"
        );

        startBlock = block.number;
        initialPrice =
            reservePrice +
            (numBlocksAuctionOpen * offerPriceDecrement);
    }

    //Calculate the current accepted price as per dutch auction rules
    function getCurrentPrice() public view returns (uint256) {
        uint256 blocksElapsed = block.number - startBlock;
        if (blocksElapsed >= numBlocksAuctionOpen) {
            return reservePrice;
        } else {
            return initialPrice - (blocksElapsed * offerPriceDecrement);
        }
    }

    function bid() external payable returns (address) {
        //Throw error if auction has already been won
        require(winner == address(0), "Auction has already concluded");

        //Throw error if auction has expired already
        require(
            (block.number - startBlock) <= numBlocksAuctionOpen,
            "Auction expired"
        );

        //Get the current accepted price as per dutch auction rules
        uint256 currentPrice = getCurrentPrice();
        //Throw error if the wei value sent is less than the current accepted price
        require(
            msg.value >= currentPrice,
            "The wei value sent is not acceptable"
        );

        //Set the bidder as winner
        //Transfer the NFT to bidder
        //Transfer the bid amount to owner
        winner = msg.sender;
        owner.transfer(msg.value);
        nft.transferFrom(owner, winner, nftTokenId);

        return winner;
    }
}

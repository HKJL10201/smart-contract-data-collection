// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTDutchAuction {
    address payable public immutable owner;
    uint256 public immutable reservePrice;
    uint256 public immutable numBlocksAuctionOpen;
    uint256 public immutable offerPriceDecrement;

    uint256 public immutable startBlock;
    uint256 public initialPrice;
    address public winner;

    IERC721 public nftToken;
    uint256 public nftTokenId;

    constructor(
        address _erc721TokenAddress,
        uint256 _nftTokenId,
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement
    ) {
        owner = payable(msg.sender);
        nftToken = IERC721(_erc721TokenAddress);
        nftTokenId = _nftTokenId;
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        startBlock = block.number;

        require(
            nftToken.ownerOf(_nftTokenId) == owner,
            "The NFT tokenId does not belong to the Auction's Owner"
        );
        initialPrice =
            reservePrice +
            (numBlocksAuctionOpen * offerPriceDecrement);
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 blocksElapsed = block.number - startBlock;
        if (blocksElapsed >= numBlocksAuctionOpen) {
            return reservePrice;
        } else {
            return initialPrice - (blocksElapsed * offerPriceDecrement);
        }
    }

    function bid() external payable returns (address) {
        require(winner == address(0), "Auction has already ended.");

        uint256 blocksElapsed = block.number - startBlock;
        require(blocksElapsed <= numBlocksAuctionOpen, "Auction ended.");

        uint256 currentPrice = getCurrentPrice();
        require(
            msg.value >= currentPrice,
            "The wei value sent is not acceptable"
        );

        winner = msg.sender;
        owner.transfer(msg.value);
        nftToken.transferFrom(owner, winner, nftTokenId);

        return winner;
    }
}

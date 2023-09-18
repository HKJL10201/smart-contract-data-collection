// SPDX-License-Identifier: MIT

/*

      .oooo.               oooooo     oooo           oooo                      o8o                       
     d8P'`Y8b               `888.     .8'            `888                      `"'                       
    888    888 oooo    ooo   `888.   .8'    .oooo.    888   .ooooo.  oooo d8b oooo  oooo  oooo   .oooo.o 
    888    888  `88b..8P'     `888. .8'    `P  )88b   888  d88' `88b `888""8P `888  `888  `888  d88(  "8 
    888    888    Y888'        `888.8'      .oP"888   888  888ooo888  888      888   888   888  `"Y88b.  
    `88b  d88'  .o8"'88b        `888'      d8(  888   888  888    .o  888      888   888   888  o.  )88b 
     `Y8bd8P'  o88'   888o       `8'       `Y888""8o o888o `Y8bod8P' d888b    o888o  `V88V"V8P' 8""888P' 

*/

pragma solidity 0.8.17;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

/// @title Dutch Auction for NFTs
/// @author 0xValerius
/// @notice This contract allows bidding on NFTs in an Dutch Auction style.
contract DutchAuction {
    /// @notice The address of the seller (auction creator)
    address payable public immutable seller;

    /// @notice The duration of the auction
    uint256 public immutable duration;

    /// @notice The starting time of the auction
    uint256 public immutable startAt;

    /// @notice The end time of the auction
    uint256 public immutable endAt;

    /// @notice The starting price of the auction
    uint256 public immutable startPrice;

    /// @notice The minimum price of the auction
    uint256 public immutable minPrice;

    /// @notice The NFT being auctioned
    IERC721 public immutable nft;

    /// @notice The token ID of the NFT being auctioned
    uint256 public immutable tokenId;

    /// @param _duration The duration of the auction
    /// @param _startAt The starting time of the auction
    /// @param _startPrice The starting price of the auction
    /// @param _minPrice The minimum price of the auction
    /// @param _nft The NFT contract address
    /// @param _tokenId The token ID of the NFT being auctioned
    constructor(
        uint256 _duration,
        uint256 _startAt,
        uint256 _startPrice,
        uint256 _minPrice,
        address _nft,
        uint256 _tokenId
    ) {
        require(_duration > 0, "DutchAuction: duration must be greater than 0.");
        require(_startAt > block.timestamp, "DutchAuction: startAt must be in the future.");
        require(_startPrice > _minPrice, "DutchAuction: startPrice must be greater than minPrice.");
        require(_minPrice > 0, "DutchAuction: minPrice must be greater than 0.");
        require(_minPrice < _startPrice, "DutchAuction: minPrice must be less than startPrice.");
        require(_nft != address(0), "DutchAuction: nft cannot be the zero address.");

        seller = payable(msg.sender);
        duration = _duration;
        startAt = _startAt;
        endAt = _startAt + _duration;
        startPrice = _startPrice;
        minPrice = _minPrice;
        nft = IERC721(_nft);
        tokenId = _tokenId;
    }

    /// @notice Checks if the auctioned NFT is escrowed by this contract
    /// @return true if the NFT is escrowed, false otherwise
    function isEscrowed() public view returns (bool) {
        return nft.ownerOf(tokenId) == address(this);
    }

    /// @notice Returns the current price of the auction
    /// @return The current price of the auction
    function getPrice() public view returns (uint256) {
        require(block.timestamp >= startAt, "DutchAuction: auction has not started yet.");
        require(block.timestamp <= endAt, "DutchAuction: auction has already ended.");
        require(isEscrowed(), "DutchAuction: NFT is not escrowed.");

        // DiscountRate = (startPrice - minPrice) / duration
        return startPrice - ((startPrice - minPrice) * (block.timestamp - startAt)) / duration;
    }

    /// @notice Allows a user to bid for the NFT in the auction
    /// @dev The sender must send enough ETH to cover the current price of the auction
    function bid() external payable {
        require(block.timestamp >= startAt, "DutchAuction: auction has not started yet.");
        require(block.timestamp <= endAt, "DutchAuction: auction has already ended.");
        require(isEscrowed(), "DutchAuction: NFT is not escrowed.");
        require(msg.sender != seller, "DutchAuction: seller cannot bid.");
        require(msg.value >= getPrice(), "DutchAuction: msg.value must be greater than or equal to current price.");

        uint256 currentPrice = getPrice();

        // Transfer ETH to seller.
        (bool sellerPayment,) = seller.call{value: currentPrice}("");
        require(sellerPayment, "DutchAuction: ETH seller payment failed.");

        // Transfer NFT to buyer.
        nft.transferFrom(address(this), msg.sender, tokenId);

        // Refund excess ETH to buyer.
        if (msg.value > currentPrice) {
            (bool refund,) = payable(msg.sender).call{value: msg.value - currentPrice}("");
            require(refund, "DutchAuction: ETH refund failed.");
        }
    }

    /// @notice Allows the seller to retrieve the NFT if there are no successful bids by the end of the auction
    /// @dev The caller must be the seller
    function noSale() external {
        require(block.timestamp > endAt, "DutchAuction: auction has not ended yet.");
        require(isEscrowed(), "DutchAuction: NFT is not escrowed.");
        require(msg.sender == seller, "DutchAuction: only seller can call this function.");

        // Transfer the NFT back to the seller.
        nft.transferFrom(address(this), msg.sender, tokenId);
    }
}

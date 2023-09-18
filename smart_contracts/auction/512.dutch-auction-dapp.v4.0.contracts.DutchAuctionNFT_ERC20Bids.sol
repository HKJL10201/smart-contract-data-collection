// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTDutchAuction_ERC20Bids is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // address payable public immutable owner;
    uint256 public reservePrice;
    uint256 public numBlocksAuctionOpen;
    uint256 public offerPriceDecrement;

    uint256 public startBlock;
    uint256 public initialPrice;
    address public winner;

    IERC721 public nftToken;
    uint256 public nftTokenId;
    IERC20 public erc20Token;

    function initialize(
        address _erc20TokenAddress,
        address _erc721TokenAddress,
        uint256 _nftTokenId,
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        nftTokenId = _nftTokenId;
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;

        nftToken = IERC721(_erc721TokenAddress);
        erc20Token = IERC20(_erc20TokenAddress);

        require(
            nftToken.ownerOf(_nftTokenId) == owner(),
            "The NFT tokenId does not belong to the Auction's Owner"
        );

        startBlock = block.number;
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

    function bid(uint256 bidAmount) external payable returns (address) {
        require(winner == address(0), "Auction has already ended.");

        uint256 blocksElapsed = block.number - startBlock;
        require(blocksElapsed <= numBlocksAuctionOpen, "Auction ended.");

        uint256 currentPrice = getCurrentPrice();
        require(
            bidAmount >= currentPrice,
            "The ERC20 value sent is not acceptable"
        );

        winner = msg.sender;
        erc20Token.transferFrom(msg.sender, owner(), bidAmount);
        // owner.transfer(msg.value);
        nftToken.transferFrom(owner(), winner, nftTokenId);

        return winner;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}

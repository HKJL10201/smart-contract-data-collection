//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./myNFTsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DigitalArtAuction is Ownable {
    struct Auction {
        uint256 highestBid;
        uint256 closingTime;
        address highestBidder;
        address originalOwner;
        bool isActive;
    }

    // NFT id => Auction data
    mapping(uint256 => Auction) public auctions;

    // Digital Art contract interface
    DigitalArt private sNft_;

    // ETH balance
    uint256 public balances;
    uint256 public gasPrice;

    event NewAuctionOpened(
        uint256 nftId,
        uint256 startingBid,
        uint256 closingTime,
        address originalOwner
    );

    event AuctionClosed(
        uint256 nftId,
        uint256 highestBid,
        address highestBidder
    );

    event BidPlaced(uint256 nftId, uint256 bidPrice, address bidder);

    /**
     * @dev Receive ETH. msg.data is empty
     */
    receive() external payable {
        balances += msg.value;
    }

    /**
     * @dev Receive ETH. msg.data is not empty
     */
    fallback() external payable {
        balances += msg.value;
    }

    /**
        Start the process 
     */
    function initialize(address _sNft) external onlyOwner {
        require(_sNft != address(0), "Invalid address");

        sNft_ = DigitalArt(_sNft);

        balances = 0;
        gasPrice = 1000; //Variable
    }

    function openAuction (
        uint256 _nftId,
        uint256 _sBid,
        uint256 _duration
    ) external {
        require(auctions[_nftId].isActive == false, "Ongoing auction detected");
        require(_duration > 0 && _sBid > 0, "Invalid input");
        require(sNft_.ownerOf(_nftId) == msg.sender, "Not NFT owner");

        // NFT Transfer to contract
        sNft_.transfer(_nftId, address(this));

        // Opening new auction
        auctions[_nftId].highestBid = _sBid;
        auctions[_nftId].closingTime = block.timestamp + _duration;
        auctions[_nftId].highestBidder = msg.sender;
        auctions[_nftId].originalOwner = msg.sender;
        auctions[_nftId].isActive = true;

        emit NewAuctionOpened(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].closingTime,
            auctions[_nftId].highestBidder
        );
    }

    function placeBid(uint256 _nftId) external payable {
        require(auctions[_nftId].isActive == true, "Not active auction");
        require(
            auctions[_nftId].closingTime > block.timestamp,
            "Auction is closed"
        );
        require(msg.value > auctions[_nftId].highestBid, "Bid is too low");

        if (auctions[_nftId].originalOwner != auctions[_nftId].highestBidder) {
            // Transfer ETH to Previous Highest Bidder
            (bool sent, ) = payable(auctions[_nftId].highestBidder).call{
                value: auctions[_nftId].highestBid
            }("");

            require(sent, "Transfer ETH failed");
        }

        auctions[_nftId].highestBid = msg.value;
        auctions[_nftId].highestBidder = msg.sender;

        emit BidPlaced(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].highestBidder
        );
    }

    function closeAuction(uint256 _nftId) external {
        require(auctions[_nftId].isActive == true, "Not active auction");
        require(
            auctions[_nftId].closingTime <= block.timestamp,
            "Auction is not closed"
        );



        // Transfer ETH to NFT Owner
        uint256 royalty = (auctions[_nftId].highestBid)/2;
        auctions[_nftId].highestBid = auctions[_nftId].highestBid - royalty;
        if (auctions[_nftId].originalOwner != auctions[_nftId].highestBidder) {
            (bool sent, ) = payable(auctions[_nftId].originalOwner).call{
                value: auctions[_nftId].highestBid
            }("");
            (bool sent1, ) = payable(sNft_.getArtist(_nftId)).call{
                value: royalty
            }("");
            require(sent, "Transfer ETH failed");
            require(sent1, "Transfer ETH failed");
        }
         
        // Transfer NFT to Highest Bidder
        sNft_.transfer(_nftId, auctions[_nftId].highestBidder);

        // Close Auction
        auctions[_nftId].isActive = false;

        emit AuctionClosed(
            _nftId,
            auctions[_nftId].highestBid,
            auctions[_nftId].highestBidder
        );
    }

    function withdraw(address _target, uint256 _amount) external onlyOwner {
        require(_target != address(0), "Invalid address");
        require(_amount > 0 && _amount < balances, "Invalid amount");

        payable(_target).transfer(_amount);

        balances = balances - _amount;
    }
}

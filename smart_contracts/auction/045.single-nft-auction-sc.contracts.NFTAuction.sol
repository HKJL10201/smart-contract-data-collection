//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title An Auction Contract for bidding one single NFT
/// @author Anthony Lau
/// @notice This contract can be used for auctioning NFTs, and accepts any ERC20 token as payment
contract NFTAuction is Ownable {
    struct Auction {
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; // Time that the auction lasts until another bid occurs
        uint64 auctionEnd;
        uint128 startPrice;
        uint128 highestBid;
        uint256 tokenId;
        address nftContractAddress;
        address highestBidder;
        address nftSeller;
        address ERC20Token; // Seller can specify an ERC20 token that can be used to bid the NFT
    }

    /** Default values that are used if not specified by the NFT seller */
    uint32 public defaultBidIncreasePercentage;
    uint32 public minimumBidIncreasePercentage;
    uint32 public defaultAuctionBidPeriod;

    Auction singleNFTAuction;

    constructor() {
        defaultBidIncreasePercentage = 1000; // 10%
        defaultAuctionBidPeriod = 86400; // 1 day
        minimumBidIncreasePercentage = 500; // minimum 5%
    }

    /** Modifiers */
    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            singleNFTAuction.nftSeller != _msgSender(),
            "Auction already started by owner"
        );

        if (singleNFTAuction.nftSeller != address(0)) {
            require(
                _msgSender() == IERC721(_nftContractAddress).ownerOf(_tokenId),
                "Caller doesn't own the NFT"
            );

            _resetAuction();
        }
        _;
    }

    modifier auctionOnGoing() {
        require(_isAuctionOnGoing(), "Auction has ended");
        _;
    }

    modifier startPriceCompliance(uint256 _startPrice) {
        require(_startPrice > 0, "Starting price cannot be 0");
        _;
    }

    modifier paymentCompliance(address _erc20Token, uint128 _bidAmount) {
        require(
            _isPaymentAccepted(_erc20Token, _bidAmount),
            "Bid has to be made in specified ERC20 token"
        );
        _;
    }

    modifier bidCompliance(uint128 _bidAmount) {
        require(
            _isNextBidHigher(_bidAmount),
            "The bid amount is less than previous bid"
        );
        _;
    }

    modifier bidIncreasePercentageCompliance(uint32 _bidIncreasePercentage) {
        require(
            _bidIncreasePercentage >= minimumBidIncreasePercentage,
            "Bid increase percentage too low"
        );
        _;
    }

    modifier notNftSeller() {
        require(
            _msgSender() != singleNFTAuction.nftSeller,
            "Seller cannot bid on own NFT"
        );
        _;
    }

    /** public GETTER */
    function _getStartPrice() public view returns (uint128) {
        return singleNFTAuction.startPrice;
    }

    function _getHighestBid() public view returns (uint128) {
        return singleNFTAuction.highestBid;
    }

    function _getHighestBidder() public view returns (address) {
        return singleNFTAuction.highestBidder;
    }

    function _getNFTSeller() public view returns (address) {
        return singleNFTAuction.nftSeller;
    }

    function _getERC20TokenAddress() public view returns (address) {
        return singleNFTAuction.ERC20Token;
    }

    function _getBidIncreasePercentage() internal view returns (uint32) {
        uint32 bidIncreasePercentage = singleNFTAuction.bidIncreasePercentage;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _getAuctionBidPeriod() public view returns (uint32) {
        uint32 auctionBidPeriod = singleNFTAuction.auctionBidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    function _getAuctionEnd() public view returns (uint64) {
        return singleNFTAuction.auctionEnd;
    }

    /** public functions */
    function makeBid(address _erc20Token, uint128 _bidAmount)
        external
        auctionOnGoing
        notNftSeller
        paymentCompliance(_erc20Token, _bidAmount)
        bidCompliance(_bidAmount)
    {
        _reversePrevBidAndUpdateHighestBid(_bidAmount);
        emit BidMade(
            singleNFTAuction.nftContractAddress,
            singleNFTAuction.tokenId,
            _msgSender(),
            _erc20Token,
            _bidAmount
        );
        _updateOnGoingAuction(
            singleNFTAuction.nftContractAddress,
            singleNFTAuction.tokenId
        );
    }

    function claimAuctionResult(address _nftContractAddress, uint256 _tokenId)
        external
    {
        require(!_isAuctionOnGoing(), "Auction is not ended yet");
        require(
            _msgSender() == singleNFTAuction.highestBidder,
            "Caller is not the highest bidder"
        );
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, _msgSender());
    }

    /** Only owner */
    // Qucikly create an auction that uses the default bid increase percentage & auction bid period
    function createDefaultNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _startPrice
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        startPriceCompliance(_startPrice)
        onlyOwner
    {
        _createNFTAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _startPrice
        );
    }

    function createNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _startPrice,
        uint32 _auctionBidPeriod,
        uint32 _bidIncreasePercentage
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        startPriceCompliance(_startPrice)
        bidIncreasePercentageCompliance(_bidIncreasePercentage)
        onlyOwner
    {
        singleNFTAuction.auctionBidPeriod = _auctionBidPeriod;
        singleNFTAuction.bidIncreasePercentage = _bidIncreasePercentage;
        _createNFTAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _startPrice
        );
    }

    /** Internal */
    function _createNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _startPrice
    ) internal {
        if (_erc20Token != address(0)) {
            singleNFTAuction.ERC20Token = _erc20Token;
        }
        singleNFTAuction.nftContractAddress = _nftContractAddress;
        singleNFTAuction.tokenId = _tokenId;
        singleNFTAuction.startPrice = _startPrice;

        singleNFTAuction.nftSeller = _msgSender();

        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            _msgSender(),
            _erc20Token,
            _startPrice,
            _getAuctionBidPeriod(),
            _getBidIncreasePercentage()
        );
        _updateOnGoingAuction(_nftContractAddress, _tokenId);
    }

    function _updateOnGoingAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        if (_isBidMade()) {
            // only escrow the nft when an actual bid is made
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd();
        }
    }

    function _updateAuctionEnd() internal {
        // The auction end time is always set by now() + bid period
        singleNFTAuction.auctionEnd =
            _getAuctionBidPeriod() +
            uint64(block.timestamp);
        emit AuctionPeriodUpdated(
            singleNFTAuction.nftContractAddress,
            singleNFTAuction.tokenId,
            singleNFTAuction.auctionEnd
        );
    }

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = singleNFTAuction.nftSeller;
        address _highestBidder = singleNFTAuction.highestBidder;
        uint128 _highestBid = singleNFTAuction.highestBid;
        _resetBids();

        _payout(_nftSeller, _highestBid);
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _highestBidder,
            _tokenId
        );

        _resetAuction();
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _highestBid,
            _highestBidder
        );
    }

    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = singleNFTAuction.nftSeller;

        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(
                _nftSeller,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "NFT transfer failed"
            );
        } else {
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "Seller doesn't own the NFT"
            );
        }
    }

    function _reversePrevBidAndUpdateHighestBid(uint128 _bidAmount) internal {
        address prevHighestBidder = singleNFTAuction.highestBidder;
        uint256 prevHighestBid = singleNFTAuction.highestBid;

        _updateHighestBid(_bidAmount);

        if (prevHighestBidder != address(0)) {
            _payout(prevHighestBidder, prevHighestBid);
        }
    }

    function _updateHighestBid(uint128 _bidAmount) internal {
        address auctionERC20Token = singleNFTAuction.ERC20Token;

        IERC20(auctionERC20Token).transferFrom(
            _msgSender(),
            address(this),
            _bidAmount
        );
        singleNFTAuction.highestBid = _bidAmount;
        singleNFTAuction.highestBidder = _msgSender();
    }

    function _resetAuction() internal {
        singleNFTAuction.startPrice = 0;
        singleNFTAuction.bidIncreasePercentage = 0;
        singleNFTAuction.auctionBidPeriod = 0;
        singleNFTAuction.auctionEnd = 0;
        singleNFTAuction.nftSeller = address(0);
        singleNFTAuction.ERC20Token = address(0);
    }

    function _resetBids() internal {
        singleNFTAuction.highestBidder = address(0);
        singleNFTAuction.highestBid = 0;
    }

    function _payout(address _recipient, uint256 _amount) internal {
        address auctionERC20Token = singleNFTAuction.ERC20Token;

        IERC20(auctionERC20Token).transfer(_recipient, _amount);
    }

    /** Internal check */
    function _isAuctionOnGoing() internal view returns (bool) {
        uint64 auctionEndTimestamp = singleNFTAuction.auctionEnd;
        // if auctionEnd is 0 which means no bid is made yet, but still on going
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    function _isBidMade() internal view returns (bool) {
        return singleNFTAuction.highestBid > 0;
    }

    function _isNextBidHigher(uint128 _bidAmount) internal view returns (bool) {
        // next bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (singleNFTAuction.highestBid *
            (10000 + _getBidIncreasePercentage())) / 10000;
        return (msg.value >= bidIncreaseAmount ||
            _bidAmount >= bidIncreaseAmount);
    }

    function _isPaymentAccepted(address _erc20Token, uint128 _bidAmount)
        internal
        view
        returns (bool)
    {
        address erc20TokenUsedToBid = singleNFTAuction.ERC20Token;

        return
            msg.value == 0 &&
            erc20TokenUsedToBid == _erc20Token &&
            _bidAmount > 0;
    }

    /** Events */
    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 minPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 bidAmount
    );

    event AuctionPeriodUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint64 auctionEndPeriod
    );

    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder
    );
}

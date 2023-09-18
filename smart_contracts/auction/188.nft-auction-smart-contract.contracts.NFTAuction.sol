// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTAuction is Ownable, ReentrancyGuard {
    //Structure of Auction
    struct AuctionData {
        address nftAddress;
        uint256 tokenId;
        uint256 highestBidAmount;
        address highestBidder;
        uint256 minLimitBidAmount;
        uint256 auctionEnd; // This is in UTC timestamp format
    }

    //Mappings for auctions: _nftAddress => tokenId => AuctionData
    mapping(address => mapping(uint256 => AuctionData)) auctionList;

    /**
     * @notice  Modifier to check if auction is ended or not.
     * @param   nftAddress : Address for NFT Contract.
     * @param   tokenId : Address for NFT Contract.
     */
    modifier isAuctionEnded(address nftAddress, uint256 tokenId) {
        require(
            block.timestamp > auctionList[nftAddress][tokenId].auctionEnd,
            "Auction is still in progress!"
        );
        _;
    }

    /**
     * @notice  Modifier to check if customer can bid or not.
     * @param   nftAddress : Address for NFT Contract.
     * @param   tokenId : Address for NFT Contract.
     */
    modifier isAuctionInProgress(address nftAddress, uint256 tokenId) {
        require(
            block.timestamp < auctionList[nftAddress][tokenId].auctionEnd,
            "Auction already ended."
        );
        _;
    }

    /**
     * @notice  Modifier to see if the account is the owner of the token.
     * @param   _nftAddress  : Address for NFT Contract.
     * @param   tokenId : Address for NFT Contract.
     */
    modifier isOwnerOfToken(address _nftAddress, uint256 tokenId) {
        require(
            IERC721(_nftAddress).ownerOf(tokenId) == msg.sender,
            "You are not the owner of that token!"
        );
        _;
    }

    /**
     * @notice  Modifier to check if the auction is exist or not.
     * @param   _nftAddress : Address for NFT Contract.
     * @param   _tokenId : Address for NFT Contract.
     */
    modifier checkAuctionExist(address _nftAddress, uint256 _tokenId) {
        require(
            auctionList[_nftAddress][_tokenId].nftAddress != address(0),
            "Auction doesn't exist for this token."
        );
        _;
    }

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/
    //Event for which will be emit when the auction is created.
    event AuctionCreated(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _minLimitBidAmount,
        uint256 _auctionEnd,
        uint256 _createdAt
    );

    //Event for which will be emit when the bid is made.
    event BidMade(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        address _bidder,
        uint256 _bidAmount,
        uint256 _bidAt
    );

    //Event for which will be emit when the auction is closed.
    event AuctionClosed(
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _highestBidAmount,
        address _highestBidder,
        uint256 _closedAt
    );

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/

    constructor() {}

    /**
     * @notice  Create an auction.
     * @param   _nftAddress : Address for NFT Contract.
     * @param   _tokenId : Address for NFT Contract.
     * @param   _minLimitBidAmount : Bid amount for the minimal limitation.
     * @param   _auctionEnd : Timestamp for the auction end.
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _minLimitBidAmount,
        uint256 _auctionEnd
    ) external payable onlyOwner {
        require(
            _auctionEnd > block.timestamp,
            "Auction end can't be less than current timestamp."
        );

        auctionList[_nftAddress][_tokenId] = AuctionData(
            _nftAddress,
            _tokenId,
            0,
            address(0),
            _minLimitBidAmount,
            _auctionEnd
        );

        //Put NFT for the auction on the contract
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

        //Emits the event.
        emit AuctionCreated(
            _nftAddress,
            _tokenId,
            _minLimitBidAmount,
            _auctionEnd,
            block.timestamp
        );
    }

    /**
     * @notice  Get the auction data for token.
     * @param   _nftAddress : Address for NFT Contract.
     * @param   _tokenID : Address for NFT Contract.
     * @return  AuctionData for the target auction with address and ID.
     */
    function getAuctionData(
        address _nftAddress,
        uint256 _tokenID
    ) external view returns (AuctionData memory) {
        return auctionList[_nftAddress][_tokenID];
    }

    /**
     * @notice  Make a bid on the auction.
     * @param   _nftAddress : Address for NFT Contract.
     * @param   _tokenId : Address for NFT Contract.
     */
    function makeBid(
        address _nftAddress,
        uint256 _tokenId
    ) external payable isAuctionInProgress(_nftAddress, _tokenId) nonReentrant {
        AuctionData storage currentAuctionData = auctionList[_nftAddress][
            _tokenId
        ];

        require(
            msg.value >= currentAuctionData.minLimitBidAmount,
            "Bid amount is too small."
        );

        require(
            msg.sender != currentAuctionData.highestBidder,
            "You are now highest bidder!"
        );

        //If the auction is not a new one, then bid amount should be higher than the current highest bid amount.
        if (currentAuctionData.highestBidder != address(0)) {
            if (msg.value <= currentAuctionData.highestBidAmount)
                revert("Bid amount should be higher than former one.");

            //Refund former bid amount to former bidder.
            _transferFund(
                currentAuctionData.highestBidder,
                currentAuctionData.highestBidAmount
            );
        }

        //Set the highest bid amount and bidder information with the new one.
        currentAuctionData.highestBidder = msg.sender;
        currentAuctionData.highestBidAmount = msg.value;

        //Emits the event
        emit BidMade(
            _nftAddress,
            _tokenId,
            msg.sender,
            msg.value,
            block.timestamp
        );
    }

    /**
     * @notice  Close auction.
     * @param   _nftAddress : Address for NFT Contract.
     * @param   _tokenId : Address for NFT Contract.
     */
    function closeAuction(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        checkAuctionExist(_nftAddress, _tokenId)
        isAuctionEnded(_nftAddress, _tokenId)
        nonReentrant
    {
        //Transfer fund to the contract owner
        _transferFund(
            owner(),
            auctionList[_nftAddress][_tokenId].highestBidAmount
        );

        //Transfer NFT to the highest bidder.
        IERC721(_nftAddress).transferFrom(
            address(this),
            auctionList[_nftAddress][_tokenId].highestBidder,
            _tokenId
        );

        // reset auction data
        _resetAuctionData(_nftAddress, _tokenId);

        //Emits the event.
        emit AuctionClosed(
            _nftAddress,
            _tokenId,
            auctionList[_nftAddress][_tokenId].highestBidAmount,
            auctionList[_nftAddress][_tokenId].highestBidder,
            block.timestamp
        );
    }

    /**
     * @notice  Internal function to reset auction data.
     * @param   _nftAddress : Address for NFT Contract.
     * @param   _tokenId : Address for NFT Contract.
     */
    function _resetAuctionData(address _nftAddress, uint256 _tokenId) internal {
        auctionList[_nftAddress][_tokenId] = AuctionData(
            address(0),
            0,
            0,
            address(0),
            0,
            0
        );
    }

    /**
     * @notice  Internal function to transfer fund.
     * @param   _to : Address for the recepient.
     * @param   amount : Amount to be sent to the recepient.
     */
    function _transferFund(address _to, uint256 amount) internal {
        payable(_to).transfer(amount);
    }
}

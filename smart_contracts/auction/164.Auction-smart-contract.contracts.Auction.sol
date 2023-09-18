// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Auction__NotOwner();
error Auction__NotRegistered();
error Auction__PriceMustBeAboveZero();
error Auction__TransferOfOwnerShipFailed();
error Auction__NotStarted();
error Auction__NotEnoughFundsSent();
error Auction__NotEnded();

contract Auction is ReentrancyGuard {
    // withdraw funds

    ////////////////////
    //// EVENTS ///////
    //////////////////

    event NftRegistered(address nftAddress, uint256 tokenId);
    event AuctionStarted(uint256 tokenId, uint256 startingPrice);
    event AuctionAborted(uint256 tokenId, address caller);
    event NftWithdrawn(uint256 tokenId, address nftAddress, address newOwner);
    event BiddedSuccessfully(
        uint256 tokenId,
        address bidder,
        uint256 amountSent
    );
    event AuctionEnded(
        uint256 tokenId,
        address nftAddress,
        address previousOwner,
        address newOwner,
        uint256 amountTradedfor
    );
    event WithdrewBidFund(
        uint256 tokenId,
        address withdrawer,
        uint256 amount,
        bool successfull
    );
    event WithdrewFund(address withdrawer, uint256 amount, bool successfull);

    ////////////////////
    //// MAPPINGS /////
    //////////////////

    //      tokenId -> AuctionDetails
    mapping(uint256 => AuctionDetails) private idToAuctionDetails;
    //      tokenId  ->         bidder  ->  priceBidded
    mapping(uint256 => mapping(address => uint256)) private idToBidderFund;
    //     registrant -> amount of fund
    mapping(address => uint256) private registrantToFunds;

    ////////////////////
    //// STRUCT ///////
    //////////////////
    struct AuctionDetails {
        address registrant;
        uint256 currentBidPrice;
        bool isRegistered;
        bool hasStarted;
    }

    ////////////////////
    //// MODIFIERS ////
    //////////////////

    /*  check if the function caller is the address that registered the item */
    modifier isRegistrant(uint256 tokenId, address caller) {
        if (idToAuctionDetails[tokenId].registrant != caller)
            revert Auction__NotOwner();
        _;
    }

    /* check if item is registered */
    modifier isRegistered(uint256 tokenId) {
        if (!idToAuctionDetails[tokenId].isRegistered)
            revert Auction__NotRegistered();
        _;
    }

    ///////////////////////
    /// MAIN FUNCTIONS ///
    //////////////////////

    /**
     * @notice Method for sending nft ownership to contract
     * @param nftAddress: Address of the nft
     * @param tokenId: The id of the nft
     * @dev The contract needs to be the new owner of the nft to avoid fraudlent practices and act as a middleman
     */

    function registerNft(address nftAddress, uint256 tokenId) public {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (owner != msg.sender) revert Auction__NotOwner();
        nft.approve(address(this), tokenId);
        nft.transferFrom(owner, address(this), tokenId);
        if (nft.ownerOf(tokenId) != address(this))
            revert Auction__TransferOfOwnerShipFailed();
        idToAuctionDetails[tokenId] = AuctionDetails(owner, 0, true, false);
        emit NftRegistered(nftAddress, tokenId);
    }

    /**
     * @notice Method for starting the auction
     * @param tokenId: The id of the nft
     * @param startingPrice: The starting price of the nft for the smart contract
     */

    function startAuction(
        uint256 tokenId,
        uint256 startingPrice
    ) public isRegistrant(tokenId, msg.sender) isRegistered(tokenId) {
        if (startingPrice <= 0) revert Auction__PriceMustBeAboveZero();
        idToAuctionDetails[tokenId] = AuctionDetails(
            msg.sender,
            startingPrice,
            true,
            true
        );
        emit AuctionStarted(tokenId, startingPrice);
    }

    /**
     * @notice Method for aborting and stoping the auction
     * @param tokenId: The id of the nft
     * @dev If the owner decides not to sell the nft
     */
    function abortAuction(
        uint256 tokenId
    ) public isRegistrant(tokenId, msg.sender) isRegistered(tokenId) {
        idToAuctionDetails[tokenId] = AuctionDetails(
            msg.sender,
            0,
            true,
            false
        );
        emit AuctionAborted(tokenId, msg.sender);
    }

    /**
     * @notice Method to unregister nft and transfer ownership back
     * @param tokenId: The id of the nft
     * @param nftAddress: The id of the nft
     * @dev If the owner decides to regain ownership of nft and not sell
     */

    function withdrawNft(
        uint256 tokenId,
        address nftAddress
    )
        public
        nonReentrant
        isRegistrant(tokenId, msg.sender)
        isRegistered(tokenId)
    {
        delete (idToAuctionDetails[tokenId]);
        IERC721(nftAddress).approve(msg.sender, tokenId);
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        emit NftWithdrawn(
            tokenId,
            nftAddress,
            IERC721(nftAddress).ownerOf(tokenId)
        );
    }

    /**
     * @notice Method to unregister nft and transfer ownership back
     * @param tokenId: The id of the nft
     * @dev This allows user to bid for the auction item
     */
    function bid(uint256 tokenId) public payable isRegistered(tokenId) {
        AuctionDetails memory details = idToAuctionDetails[tokenId];
        if (msg.value < details.currentBidPrice)
            revert Auction__NotEnoughFundsSent();
        idToBidderFund[tokenId][msg.sender] += msg.value;
        details.currentBidPrice += msg.value;
        emit BiddedSuccessfully(tokenId, msg.sender, msg.value);
    }

    function endAuction(
        uint256 tokenId,
        address nftAddress,
        address winner
    )
        public
        isRegistrant(tokenId, msg.sender)
        isRegistered(tokenId)
        nonReentrant
    {
        AuctionDetails memory details = idToAuctionDetails[tokenId];
        if (!details.hasStarted) revert Auction__NotStarted();
        registrantToFunds[msg.sender] += idToBidderFund[tokenId][winner];
        IERC721(nftAddress).approve(msg.sender, tokenId);
        IERC721(nftAddress).transferFrom(address(this), winner, tokenId);
        uint256 fundFor = idToBidderFund[tokenId][winner];
        delete (idToBidderFund[tokenId][winner]);
        delete (idToAuctionDetails[tokenId]);
        emit AuctionEnded(tokenId, nftAddress, msg.sender, winner, fundFor);
    }

    function withdrawBid(uint256 tokenId) public nonReentrant {
        uint256 fund = idToBidderFund[tokenId][msg.sender];
        (bool success, ) = payable(msg.sender).call{value: fund}("");
        delete (idToBidderFund[tokenId][msg.sender]);
        emit WithdrewBidFund(tokenId, msg.sender, fund, success);
    }

    function withdrawFunds() public nonReentrant {
        uint256 fund = registrantToFunds[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: fund}("");
        delete (registrantToFunds[msg.sender]);
        emit WithdrewFund(msg.sender, fund, success);
    }
}

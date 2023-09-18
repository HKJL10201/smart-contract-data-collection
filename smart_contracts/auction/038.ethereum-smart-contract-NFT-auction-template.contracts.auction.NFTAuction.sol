// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./utils/EnumerableUintSet.sol";

contract NFTAuction is
    Initializable,
    IERC721Receiver,
    ContextUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // using SafeERC20Upgradeable for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    function initialize() public initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        extendBlock = 1; //200
        maxExtendBlock = 20; //1200
    }

    modifier validNFTContractAddress(address _address) {
        require(_address != address(0) && _address != address(this));
        _;
    }

    address public treasury;
    // fee when auction finish if auction success
    uint256 public serviceFee;
    // fee for create an auction;
    uint256 public initialAuctionFee;
    address private lfwCreatorContract;
    uint256 private extendBlock;
    uint256 private maxExtendBlock;

    event InitialAuctionFeeUpdated(uint256 serviceFee);
    event ServiceFeeUpdated(uint256 serviceFee);

    /// @dev Gets the NFT object from an address, validating that implementsERC721 is true.
    /// @param nftAddress - Address of the NFT.
    function getNftContract(address nftAddress)
        internal
        pure
        returns (IERC721)
    {
        IERC721 candidateContract = IERC721(nftAddress);
        return candidateContract;
    }

    modifier onlyCreator(address _contractNFT, uint256 _tokenId) {
        require(lfwCreatorContract == msg.sender);
        _;
    }

    modifier onlySeller(address _contractNFT, uint256 _tokenId) {
        require(
            auctions[_contractNFT][_tokenId].owner == msg.sender,
            "NFTAuction: Only Seller"
        );
        _;
    }
    modifier onlyWhitelistNFTContract(address _contractNFT) {
        require(
            contractsWhitelisted.contains(_contractNFT),
            "NFTAuction: contract must be whitelisted"
        );
        _;
    }

    function setInitialAuctionFee(uint256 _initialAuctionFee)
        external
        onlyOwner
    {
        require(_initialAuctionFee >= 0, "Initial Auction fee invalid");

        initialAuctionFee = _initialAuctionFee;
        emit InitialAuctionFeeUpdated(initialAuctionFee);
    }

    function setServiceFee(uint256 _serviceFee) external onlyOwner {
        require(_serviceFee >= 0 && _serviceFee <= 100, "service fee invalid");

        serviceFee = _serviceFee;
        emit ServiceFeeUpdated(serviceFee);
    }

    function getTreasury() external view returns (address) {
        return treasury;
    }

    function whitelistContract(address _contractNFT) public onlyOwner {
        contractsWhitelisted.add(_contractNFT);
        emit ContractNFTWhitelisted(_contractNFT);
    }

    function deWhitelistContract(address _contractNFT) public onlyOwner {
        contractsWhitelisted.remove(_contractNFT);
        emit ContractNFTDeWhitelisted(_contractNFT);
    }

    struct Auction {
        // Price (in wei)
        uint256 startPrice;
        // Current owner of NFT
        address owner;
        // minimum price increace each bid
        uint256 bidStep;
        // start block of auction
        uint256 startBlock;
        // end block of auction
        uint256 endBlock;
        // end block of auction after extended
        uint256 endBlockExtend;
        // pause auction by deployer
        bool pause;
        // highest bid address
        address bidder;
        //highest bid amount
        uint256 bidAmount;
    }

    struct BidClaim {
        // Bid amount (in wei)
        uint256 amount;
        // Current owner of bid
        address owner;
    }
    // mapping address of NFT to mapping of tọkenid => auction info.
    mapping(address => mapping(uint256 => Auction)) auctions;
    // mapping address of NFT to mapping of tọkenid => auction info.
    mapping(address => mapping(uint256 => BidClaim)) bidClaims;
    EnumerableSet.AddressSet private contractsWhitelisted;
    mapping(address => EnumerableUintSet.UintSet) private contractsTokenIdsList;
    mapping(uint256 => address) private _auctionIDtoSellerAddress;
    mapping(address => uint256) failedTransferCredits;

    uint256 auctionId;
    uint256 maxSlotPerUser;
    // seller must pay fee for marketplace.
    uint256 auctionFee;
    event NewAuctionNFTCreated(
        address indexed contractNFT,
        uint256 tokenId,
        uint256 price,
        uint256 step,
        uint256 startBlock,
        uint256 endBlock,
        address seller
    );
    event NewAuctionNFTBid(
        address indexed contractNFT,
        address bidder,
        uint256 tokenId,
        uint256 price,
        uint256 endBlock
    );
    event NewStartAndEndBlocks(
        address indexed contractNFT,
        uint256 tokenId,
        uint256 startBlock,
        uint256 endBlock
    );

    event NewStartPrice(
        address indexed contractNFT,
        uint256 tokenId,
        uint256 startPrice
    );

    event AuctionNFTCanceled(
        address indexed contractNFT,
        uint256 tokenId,
        uint256 price,
        uint256 endBlock,
        address seller
    );

    event AuctionNFTFinished(
        address indexed contractNFT,
        uint256 tokenId,
        uint256 price,
        uint256 endBlock,
        address seller,
        address winner
    );
    event AuctionNFTWithdrawCredit(address indexed sender, uint256 amount);
    event ContractNFTWhitelisted(address indexed contractNFT);
    event ContractNFTDeWhitelisted(address indexed contractNFT);

    /**
     * @dev
     */
    function createAuction(
        address _contractNFT,
        uint256 tokenId,
        uint256 startPrice,
        uint256 step,
        uint256 startBlock,
        uint256 endBlock,
        address sender
    ) external payable onlyWhitelistNFTContract(_contractNFT) {
        address seller = msg.sender;
        IERC721 nft721Contract = getNftContract(_contractNFT);
        require(
            nft721Contract.ownerOf(tokenId) == seller,
            "Marketplace: not an owner of token"
        );
        require(sender != address(0) && sender != address(this));
        require(block.number < startBlock, "Auction has started");
        require(
            startBlock < endBlock,
            "New startBlock must be lower than new endBlock"
        );

        // check max slot.
        // pay auction service fee
        if (initialAuctionFee > 0) {
            payable(treasury).transfer(initialAuctionFee);
        }

        //send nft to auction contract
        nft721Contract.safeTransferFrom(seller, address(this), tokenId);

        Auction memory auction = Auction(
            startPrice,
            seller,
            step,
            startBlock,
            endBlock,
            endBlock,
            false,
            address(0),
            0
        );
        auctions[_contractNFT][tokenId] = auction;

        emit NewAuctionNFTCreated(
            _contractNFT,
            tokenId,
            startPrice,
            step,
            startBlock,
            endBlock,
            seller
        );
    }

    function bid(address _contractNFT, uint256 _tokenId)
        external
        payable
        onlyWhitelistNFTContract(_contractNFT)
        nonReentrant
    {
        // avoid insert transaction before previous highest bid in same block.
        // avoid claim money of invalid address.
        Auction storage auction = auctions[_contractNFT][_tokenId];
        require(
            block.number <= auction.endBlockExtend,
            "NFTAuction: Auction ended"
        );
        require(
            block.number >= auction.startBlock,
            "NFTAuction: Auction not started"
        );
        uint256 minBid = auction.bidAmount > 0
            ? auction.bidAmount + auction.bidStep
            : auction.startPrice;
        require(msg.value >= minBid, "NFTAuction: Bid amount invalid");
        address previousBidder = auction.bidder;
        uint256 previousBidAmount = auction.bidAmount;

        // hold bid amount of higher bidder
        payable(address(this)).transfer(msg.value);

        auction.bidder = msg.sender;
        auction.bidAmount = msg.value;

        // extend block end time
        if (
            (auction.endBlockExtend - block.number) < maxExtendBlock &&
            (auction.endBlockExtend + extendBlock) <
            (auction.endBlock + maxExtendBlock)
        ) {
            auction.endBlockExtend = auction.endBlockExtend + extendBlock;
        }

        // refund to previous bidder
        if (previousBidder != address(0)) {
            payout(previousBidder, previousBidAmount);
        }

        emit NewAuctionNFTBid(
            _contractNFT,
            msg.sender,
            _tokenId,
            msg.value,
            auction.endBlockExtend
        );
    }

    function cancelAuction(address _contractNFT, uint256 _tokenId)
        external
        onlySeller(_contractNFT, _tokenId)
        onlyWhitelistNFTContract(_contractNFT)
        nonReentrant
    {
        Auction storage auction = auctions[_contractNFT][_tokenId];
        require(
            address(auction.owner) != address(0),
            "NFTAuction: Auction is not created"
        );
        require(msg.sender == auction.owner, "NFTAuction: Auction is running");

        require(
            block.number < auction.startBlock,
            "NFTAuction: Auction is running"
        );

        IERC721 nft721Contract = getNftContract(_contractNFT);

        nft721Contract.safeTransferFrom(address(this), auction.owner, _tokenId);
        emit AuctionNFTCanceled(
            _contractNFT,
            _tokenId,
            auction.startPrice,
            auction.endBlock,
            msg.sender
        );

        resetBids(_contractNFT, _tokenId);
    }

    function claimBid(address _contractNFT, uint256 _tokenId)
        external
        onlyWhitelistNFTContract(_contractNFT)
        nonReentrant
    {
        Auction storage auction = auctions[_contractNFT][_tokenId];
        require(
            block.number > auction.endBlockExtend,
            "NFTAuction: Auction is running"
        );
        require(
            address(0) != auction.owner,
            "NFTAuction: Auction is not created"
        );

        // transfer NFT to winner or seller if auction dont have bid

        if (auction.bidder != address(0)) {
            IERC721 nft721Contract = getNftContract(_contractNFT);
            nft721Contract.safeTransferFrom(
                address(this),
                auction.bidder,
                _tokenId
            );
        } else {
            _refundNFT(_contractNFT, _tokenId);
        }

        // // transfer fee to collector.
        uint256 feeAmount = 0;
        // if (serviceFee > 0) {
        //     feeAmount = (auction.bidAmount.mul(serviceFee)).div(100);
        //     payable(treasury).transfer(feeAmount);
        //     // payable(address(treasury)).transfer(feeAmount);
        // }

        // transfer money to seller.
        payable(address(auction.owner)).transfer(auction.bidAmount - feeAmount);

        emit AuctionNFTFinished(
            _contractNFT,
            _tokenId,
            auction.bidAmount,
            auction.endBlockExtend,
            auction.owner,
            auction.bidder
        );

        //
        resetBids(_contractNFT, _tokenId);
    }

    /**
     * @dev only seller can update auction
     */
    function updateAuctionStartAndEndBlocks(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _startBlock,
        uint256 _endBlock,
        address _sender
    )
        external
        onlySeller(_contractNFT, _tokenId)
        onlyWhitelistNFTContract(_contractNFT)
    {
        Auction storage auction = auctions[_contractNFT][_tokenId];
        require(auction.owner == _sender, "NFTAuction: You are not owner");
        require(
            block.number < auction.startBlock,
            "NFTAuction: Auction has started"
        );
        require(
            _startBlock < _endBlock,
            "NFTAuction: New startBlock must be lower than new endBlock"
        );
        require(
            block.number < _startBlock,
            "NFTAuction: New startBlock must be higher than current block"
        );

        auction.startBlock = _startBlock;
        auction.endBlock = _endBlock;

        emit NewStartAndEndBlocks(
            _contractNFT,
            _tokenId,
            _startBlock,
            _endBlock
        );
    }

    /**
     * @dev only seller can update auction
     */
    function updateAuctionStartPrice(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _startPrice
    )
        external
        onlySeller(_contractNFT, _tokenId)
        onlyWhitelistNFTContract(_contractNFT)
    {
        Auction storage auction = auctions[_contractNFT][_tokenId];
        require(auction.owner == msg.sender, "NFTAuction: You are not owner");
        require(
            block.number < auction.startBlock,
            "NFTAuction: Auction has started"
        );
        auction.startPrice = _startPrice;

        emit NewStartPrice(_contractNFT, _tokenId, _startPrice);
    }

    /**
     * @notice pay a user, if not success user can claim later
     */
    function payout(address _recipient, uint256 _amount) internal {
        // attempt to send the funds to the recipient
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        //  (bool success ) = payable(_recipient).transfer(_amount);
        // if it failed, update their credit balance so they can pull it later
        if (!success) {
            failedTransferCredits[_recipient] =
                failedTransferCredits[_recipient] +
                _amount;
        }
    }

    /*
     * @notice If the transfer of a bid has failed, allow the recipient to reclaim their amount later.
     */
    function withdrawAllFailedCredits() external nonReentrant {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "NFTAuction: no credits to withdraw");

        delete failedTransferCredits[msg.sender];

        (bool successfulWithdraw, ) = msg.sender.call{value: amount}("");
        require(successfulWithdraw, "NFTAuction: withdraw failed");
        emit AuctionNFTWithdrawCredit(msg.sender, amount);
    }

    function getPendingCredit() external view returns (uint256) {
        uint256 amount = failedTransferCredits[msg.sender];

        return amount;
    }

    /*
     * Reset all bid related parameters for an NFT.
     * This effectively sets an NFT as having no active bids
     */
    function resetBids(address _contractNFT, uint256 _tokenId) internal {
        // auctions[_contractNFT][_tokenId].bidder = address(0);
        // auctions[_contractNFT][_tokenId].bidAmount = 0;
        // auctions[_contractNFT][_tokenId].nftRecipient = address(0);
        delete auctions[_contractNFT][_tokenId];
    }

    /*
     * Reset all bid related parameters for an NFT.
     * This effectively sets an NFT as having no active bids
     */
    function _refundNFT(address _contractNFT, uint256 _tokenId) internal {
        IERC721 nft721Contract = getNftContract(_contractNFT);
        nft721Contract.safeTransferFrom(
            address(this),
            auctions[_contractNFT][_tokenId].owner,
            _tokenId
        );
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0) && _treasury != address(this));
        treasury = _treasury;
    }

    function getAuction(address _contractNFT, uint256 _tokenId)
        external
        view
        returns (uint256 price, address owner)
    {
        Auction storage listing = auctions[_contractNFT][_tokenId];
        // require(listingExists(listing));
        return (listing.startPrice, listing.owner);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // function onERC1155Received(
    //     address operator,
    //     address from,
    //     uint256 id,
    //     uint256 value,
    //     bytes calldata data
    // )
    // external
    // override
    // returns(bytes4)
    // {
    //     return this.onERC1155Received.selector;
    // }
    // function onERC1155BatchReceived(
    //     address operator,
    //     address from,
    //     uint256[] calldata ids,
    //     uint256[] calldata values,
    //     bytes calldata data
    // )
    // external
    // override
    // returns(bytes4)
    // {
    //     return this.onERC1155BatchReceived.selector;
    // }
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override
    //     returns (bool)
    // {
    //     return this.supportsInterface(interfaceId);
    // }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

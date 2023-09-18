// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                            IMPORTS                          //
//=============================================================//
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./NftsManagerBase.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  NFTs auction
 * @notice It allows users to bid a specific ERC20 token amount (usually stable coins) for a ERC721 or ERC1155 NFT.
 *         The auctions are set by the contract owner.
 */
contract NftsAuction is 
    ReentrancyGuard,
    NftsManagerBase
{
    //=============================================================//
    //                        ENUMERATIVES                         //
    //=============================================================//

    /// Auction states
    enum AuctionStates { 
        INACTIVE,
        ACTIVE,
        COMPLETED
    }

    //=============================================================//
    //                         STRUCTURES                          //
    //=============================================================//

    /// Structure for auctioning a token
    struct Auction {
        uint256 nftAmount;          // Only used for ERC1155 (always 0 for ERC721)
        address highestBidder;
        IERC20 erc20Contract;
        uint256 erc20StartPrice;
        uint256 erc20MinimumBidIncrement;
        uint256 erc20HighestBid;
        uint256 startTime;
        uint256 endTime;
        uint256 extendTimeSec;
        AuctionStates state;
    }

    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if a token auction is already active for the `nftContract` and `nftId`
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    error AuctionAlreadyActiveError(
        address nftContract,
        uint256 nftId
    );

    /**
     * Error raised if a token auction is not active for the `nftContract` and `nftId`
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    error AuctionNotActiveError(
        address nftContract,
        uint256 nftId
    );

    /**
     * Error raised if a token auction is not expired for the `nftContract` and `nftId`
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    error AuctionNotExpiredError(
        address nftContract,
        uint256 nftId
    );

    /**
     * Error raised if `bidder` is not the auction winner
     * @param bidder Bidder address
     */
    error BidderNotWinnerError(
        address bidder
    );

    //=============================================================//
    //                             EVENTS                          //
    //=============================================================//

    /**
     * Event emitted when a token auction is created
     * @param nftContract              NFT contract address
     * @param nftId                    NFT ID
     * @param nftAmount_               NFT amount
     * @param erc20Contract            ERC20 contract address
     * @param erc20StartPrice          ERC20 start price
     * @param erc20MinimumBidIncrement Minimum bid increment in ERC20 token
     * @param startTime                Start time
     * @param durationSec              Duration in seconds
     * @param extendTimeSec            Extend time in seconds
     */
    event AuctionCreated(
        address nftContract,
        uint256 nftId,
        uint256 nftAmount_,
        IERC20 erc20Contract,
        uint256 erc20StartPrice,
        uint256 erc20MinimumBidIncrement,
        uint256 startTime,
        uint256 durationSec,
        uint256 extendTimeSec
    );

    /**
     * Event emitted when a token auction is removed
     * @param nftContract NFT contract address
     * @param nftId       NFT ID
     */
    event AuctionRemoved(
        address nftContract,
        uint256 nftId
    );

    /**
     * Event emitted when a token auction is bid
     * @param nftContract    NFT contract address
     * @param nftId          NFT ID
     * @param bidder         Bidder address
     * @param erc20Contract  ERC20 contract address
     * @param erc20BidAmount Bid amount in ERC20 token
     */
    event AuctionBid(
        address nftContract,
        uint256 nftId,
        address bidder,
        IERC20 erc20Contract,
        uint256 erc20BidAmount
    );

    /**
     * Event emitted when a token auction is completed
     * @param nftContract    NFT contract address
     * @param nftId          NFT ID
     * @param nftAmount      NFT amount
     * @param bidder         Bidder address
     * @param erc20Contract  ERC20 contract address
     * @param erc20Amount    ERC20 amount
     */
    event AuctionCompleted(
        address nftContract,
        uint256 nftId,
        uint256 nftAmount,
        address bidder,
        IERC20 erc20Contract,
        uint256 erc20Amount
    );

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Mapping from token address and ID to auction data
    mapping(address => mapping(uint256 => Auction)) public Auctions;

    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    /**
     * Get if an auction is active
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @return True if active, false otherwise
     */
    function isAuctionActive(
        address nftContract_,
        uint256 nftId_
    ) external view returns (bool) {
        Auction storage auction = Auctions[nftContract_][nftId_];
        return __isAuctionActive(auction);
    }

    /**
     * Get if an auction is expired
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @return True if expired, false otherwise
     */
    function isAuctionExpired(
        address nftContract_,
        uint256 nftId_
    ) external view returns (bool) {
        Auction storage auction = Auctions[nftContract_][nftId_];
        return __isAuctionExpired(auction);
    }

    /**
     * Get if an auction is completed
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @return True if completed, false otherwise
     */
    function isAuctionCompleted(
        address nftContract_,
        uint256 nftId_
    ) external view returns (bool) {
        Auction storage auction = Auctions[nftContract_][nftId_];
        return __isAuctionCompleted(auction);
    }

    /**
     * Create a ERC721 token auction
     * The NFT shall be owned by the contract
     * @param nftContract_              NFT contract address
     * @param nftId_                    NFT ID
     * @param erc20Contract_            ERC20 contract address
     * @param erc20StartPrice_          Starting price for the auction in ERC20 token
     * @param erc20MinimumBidIncrement_ Minimum bid increment in ERC20 token
     * @param durationSec_              Duration in seconds
     * @param extendTimeSec_            Extend time in seconds
     */
    function createERC721Auction(
        IERC721 nftContract_,
        uint256 nftId_,
        IERC20 erc20Contract_,
        uint256 erc20StartPrice_,
        uint256 erc20MinimumBidIncrement_,
        uint256 durationSec_,
        uint256 extendTimeSec_
    ) public onlyOwner {
        __createAuction(
            address(nftContract_),
            nftId_,
            0,
            erc20Contract_,
            erc20StartPrice_,
            erc20MinimumBidIncrement_,
            durationSec_,
            extendTimeSec_
        );
    }

    /**
     * Create a ERC1155 token auction
     * The NFT shall be owned by the contract
     * @param nftContract_              NFT contract address
     * @param nftId_                    NFT ID
     * @param nftAmount_                NFT amount
     * @param erc20Contract_            ERC20 contract address
     * @param erc20StartPrice_          Starting price for the auction in ERC20 token
     * @param erc20MinimumBidIncrement_ Minimum bid increment in ERC20 token
     * @param durationSec_              Duration in seconds
     * @param extendTimeSec_            Extend time in seconds
     */
    function createERC1155Auction(
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20StartPrice_,
        uint256 erc20MinimumBidIncrement_,
        uint256 durationSec_,
        uint256 extendTimeSec_
    )
        public
        onlyOwner
        notZeroAmount(nftAmount_)
    {
        __createAuction(
            address(nftContract_),
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20StartPrice_,
            erc20MinimumBidIncrement_,
            durationSec_,
            extendTimeSec_
        );
    }

    /**
     * Remove a token auction
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function removeAuction(
        address nftContract_,
        uint256 nftId_
    ) public onlyOwner {
        __removeAuction(nftContract_, nftId_);
    }

    /**
     * Withdraw ERC721 token to owner.
     * The token auction shall not be active. In case it is, it shall be removed before calling the function.
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function withdrawERC721(
        IERC721 nftContract_,
        uint256 nftId_
    ) public onlyOwner {
        __withdraw(
            address(nftContract_),
            nftId_,
            0
        );
    }

    /**
     * Withdraw ERC1155 token to owner.
     * The token auction shall not be active. In case it is, it shall be removed before calling the function.
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount
     */
    function withdrawERC1155(
        IERC1155 nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        public
        onlyOwner
        notZeroAmount(nftAmount_)
    {
        __withdraw(
            address(nftContract_),
            nftId_,
            nftAmount_
        );
    }

    /**
     * Bid at a token auction.
     * The bidder shall have at least `erc20BidAmount_` ERC20 token in the wallets to bid.
     * @param nftContract_    NFT contract address
     * @param nftId_          NFT ID
     * @param erc20BidAmount_ Bid amount in ERC20 token
     */
    function bidAtAuction(
        address nftContract_,
        uint256 nftId_,
        uint256 erc20BidAmount_
    ) public nonReentrant {
        __bidAtAuction(
            nftContract_,
            nftId_,
            erc20BidAmount_
        );
    }

    /**
     * Complete a token auction
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function completeAuction(
        address nftContract_,
        uint256 nftId_
    ) public nonReentrant {
        __completeAuction(
            nftContract_,
            nftId_
        );
    }

    //=============================================================//
    //                      INTERNAL FUNCTIONS                     //
    //=============================================================//

    /**
     * Initialize the auction `auction_`
     * @param auction_                  Auction structure
     * @param nftAmount_                NFT amount
     * @param erc20Contract_            ERC20 contract address
     * @param erc20StartPrice_          Starting price for the auction in ERC20 token
     * @param erc20MinimumBidIncrement_ Minimum bid increment in ERC20 token
     * @param durationSec_              Duration in seconds
     * @param extendTimeSec_            Extend time in seconds
     */
    function __initAuction(
        Auction storage auction_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20StartPrice_,
        uint256 erc20MinimumBidIncrement_,
        uint256 durationSec_,
        uint256 extendTimeSec_
    ) private {
        auction_.highestBidder = address(0);
        auction_.nftAmount = nftAmount_;
        auction_.erc20Contract = erc20Contract_;
        auction_.erc20StartPrice = erc20StartPrice_;
        auction_.erc20MinimumBidIncrement = erc20MinimumBidIncrement_;
        auction_.erc20HighestBid = erc20StartPrice_;
        auction_.startTime = block.timestamp;
        auction_.endTime = block.timestamp + durationSec_;
        auction_.extendTimeSec = extendTimeSec_;
        auction_.state = AuctionStates.ACTIVE;
    }

    /**
     * Get if the auction `auction_` is active
     * @param auction_ Auction structure
     * @return True if active, false otherwise
     */
    function __isAuctionActive(
        Auction storage auction_
    ) private view returns (bool) {
        return (auction_.state == AuctionStates.ACTIVE) && (block.timestamp <= auction_.endTime);
    }

    /**
     * Get if the auction `auction_` is expired
     * @param auction_ Auction structure
     * @return True if expired, false otherwise
     */
    function __isAuctionExpired(
        Auction storage auction_
    ) private view returns (bool) {
        return (auction_.state == AuctionStates.ACTIVE) && (block.timestamp > auction_.endTime);
    }

    /**
     * Get if the auction `auction_` is completed
     * @param auction_ Auction structure
     * @return True if completed, false otherwise
     */
    function __isAuctionCompleted(
        Auction storage auction_
    ) private view returns (bool) {
        return (auction_.state == AuctionStates.COMPLETED) && (block.timestamp > auction_.endTime);
    }

    /**
     * Create a ERC721 token auction
     * The NFT shall be owned by the contract
     * @param nftContract_              NFT contract address
     * @param nftId_                    NFT ID
     * @param nftAmount_                NFT amount
     * @param erc20Contract_            ERC20 contract address
     * @param erc20StartPrice_          Starting price for the auction in ERC20 token
     * @param erc20MinimumBidIncrement_ Minimum bid increment in ERC20 token
     * @param durationSec_              Duration in seconds
     * @param extendTimeSec_            Extend time in seconds
     */
    function __createAuction(
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_,
        IERC20 erc20Contract_,
        uint256 erc20StartPrice_,
        uint256 erc20MinimumBidIncrement_,
        uint256 durationSec_,
        uint256 extendTimeSec_
    ) 
        private
        notNullAddress(address(erc20Contract_)) 
        notZeroAmount(erc20MinimumBidIncrement_)
        notZeroAmount(durationSec_)
    {
        if (nftAmount_ == 0) {
            _validateERC721(IERC721(nftContract_), nftId_);
        }
        else {
            _validateERC1155(IERC1155(nftContract_), nftId_, nftAmount_);
        }

        Auction storage auction = Auctions[nftContract_][nftId_];
        if (__isAuctionActive(auction)) {
            revert AuctionAlreadyActiveError(nftContract_, nftId_);
        }

        __initAuction(
            auction,
            nftAmount_,
            erc20Contract_,
            erc20StartPrice_,
            erc20MinimumBidIncrement_,
            durationSec_,
            extendTimeSec_
        );

        emit AuctionCreated(
            nftContract_,
            nftId_,
            nftAmount_,
            erc20Contract_,
            erc20StartPrice_,
            erc20MinimumBidIncrement_,
            block.timestamp,
            durationSec_,
            extendTimeSec_
        );
    }

    /**
     * Remove a token auction
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function __removeAuction(
        address nftContract_,
        uint256 nftId_
    )
        private
        notNullAddress(address(nftContract_))
    {
        Auction storage auction = Auctions[nftContract_][nftId_];
        if (!__isAuctionActive(auction) && !__isAuctionExpired(auction)) {
            revert AuctionNotActiveError(nftContract_, nftId_);
        }

        auction.state = AuctionStates.INACTIVE;

        emit AuctionRemoved(nftContract_, nftId_);
    }

    /**
     * Withdraw token to owner
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     * @param nftAmount_   NFT amount (ignored for ERC721)
     */
    function __withdraw(
        address nftContract_,
        uint256 nftId_,
        uint256 nftAmount_
    )
        private
        notNullAddress(nftContract_)
    {
        address target = owner();

        Auction storage auction = Auctions[nftContract_][nftId_];
        if (__isAuctionActive(auction)) {
            if (nftAmount_ == 0) {
                revert WithdrawError(nftContract_, nftId_);
            }
            uint256 withdrawable_amount = IERC1155(nftContract_).balanceOf(address(this), nftId_) - auction.nftAmount;
            if (nftAmount_ > withdrawable_amount) {
                revert WithdrawError(nftContract_, nftId_);
            }
        }

        if (nftAmount_ == 0) {
            _withdrawERC721(
                target, 
                IERC721(nftContract_),
                nftId_
            );
        } 
        else {
            _withdrawERC1155(
                target, 
                IERC1155(nftContract_),
                nftId_,
                nftAmount_
            );
        }
    }

    /**
     * Bid at a token auction
     * @param nftContract_    NFT contract address
     * @param nftId_          NFT ID
     * @param erc20BidAmount_ Bid amount in ERC20 token
     */
    function __bidAtAuction(
        address nftContract_,
        uint256 nftId_,
        uint256 erc20BidAmount_
    )
        private
        notNullAddress(nftContract_)
    {
        Auction storage auction = Auctions[nftContract_][nftId_];
        if (!__isAuctionActive(auction)) {
            revert AuctionNotActiveError(nftContract_, nftId_);
        }
        if (erc20BidAmount_ < (auction.erc20HighestBid + auction.erc20MinimumBidIncrement)) {
            revert AmountError();
        }

        address bidder = _msgSender();
        if (auction.erc20Contract.balanceOf(bidder) < erc20BidAmount_) {
            revert AmountError();
        }

        auction.highestBidder = bidder;
        auction.erc20HighestBid = erc20BidAmount_;

        // Extend auction time if needed
        if ((auction.endTime - block.timestamp) < auction.extendTimeSec) {
            auction.endTime += auction.extendTimeSec;
        }

        emit AuctionBid(
            nftContract_,
            nftId_,
            bidder,
            auction.erc20Contract,
            erc20BidAmount_
        );
    }

    /**
     * Complete auction
     * @param nftContract_ NFT contract address
     * @param nftId_       NFT ID
     */
    function __completeAuction(
        address nftContract_,
        uint256 nftId_
    )
        private
        notNullAddress(nftContract_)
    {
        Auction storage auction = Auctions[nftContract_][nftId_];
        if (!__isAuctionExpired(auction)) {
            revert AuctionNotExpiredError(nftContract_, nftId_);
        }

        address bidder = _msgSender();
        if (bidder != auction.highestBidder) {
            revert BidderNotWinnerError(bidder);
        }

        auction.state = AuctionStates.COMPLETED;

        if (auction.nftAmount == 0) {
            _transferERC721InExchangeOfERC20(
                bidder,
                IERC721(nftContract_),
                nftId_,
                auction.erc20Contract,
                auction.erc20HighestBid
            );
        }
        else {
            _transferERC1155InExchangeOfERC20(
                bidder,
                IERC1155(nftContract_),
                nftId_,
                auction.nftAmount,
                auction.erc20Contract,
                auction.erc20HighestBid
            );
        }

        emit AuctionCompleted(
            nftContract_,
            nftId_,
            auction.nftAmount,
            bidder,
            auction.erc20Contract,
            auction.erc20HighestBid
        );
    }
}

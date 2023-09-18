// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IRegistry.sol";

/// @notice Allows selling bundles of ERC1155 NFTs and ERC721 at a fix price
/// @dev Assumes the existence of a Registry as specified in IRegistry
/// @dev Assumes an ERC2981-compliant NFT, as specified below
contract Marketplace is ERC721Holder, ERC1155Holder, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                          STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint128 public saleIdCounter; // saleIdCounter starts from 1
    uint128 public auctionIdCounter; // _autionId starts from 1

    // address alias for using ETH as a currency
    address private constant ETH =
        address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa);
    IRegistry private immutable _REGISTRY;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SaleCreated(
        uint256 indexed id,
        address indexed nftAddress,
        uint256 indexed nftID
    );
    event SaleCancelled(uint256 indexed saleId);
    event Purchase(
        uint256 indexed saleId,
        address indexed purchaser,
        address indexed recipient
    );
    event ClaimSaleNFTs(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed amount
    );
    event ClaimFunds(
        address indexed accountOf,
        address indexed tokenAddress,
        uint256 indexed newBalance
    );

    event NewAuction(uint256 indexed auctionId, AuctionInfo newAuction);
    event AuctionCancelled(uint256 indexed auctionId);
    event BidPlaced(uint256 indexed auctionId, uint256 totalAmount);
    event ClaimAuctionNFT(
        uint256 indexed auctionId,
        address indexed claimer,
        address indexed recipient,
        uint256 amount
    );
    event BalanceUpdated(
        address indexed accountOf,
        address indexed tokenAddress,
        uint256 indexed newBalance
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CanOnlySellOneNFT();
    error ContractIsDeprecated();
    error SaleIsNotActive();
    error ZeroAddressNotAllowed();
    error NotEnoughStock();
    error NotEnoughBalance();
    error InputValueAndPriceMismatch();
    error SaleIsNotClosed();
    error OnlyNFTOwnerCanClaim();
    error StockAlreadySoldOrClaimed();
    error NothingToClaim();
    error OnlyOwnerOrSaleCreator();
    error SaleMustBeActiveOrPending();
    error AuctionIsNotActive();
    error BidIsNotHighEnough();
    error BidLoweThanReservePrice();
    error ArgumentsAndValueMismatch();
    error AuctionIsNotEndOrCancelled();
    error OnlyOwnerOrAuctionCreator();
    error AuctionMustBeActiveOrPending();
    error AuctionDoesNotExist();
    error SaleDoesNotExist();
    error NFTContractIsNotApproved();
    error CurrencyIsNotSupported();
    error ContractMustSupportERC2981();
    error EndTimeMustBeGreaterThanStartTime();
    error UnexpectedError();

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SaleInfo {
        uint128 nftId;
        bool isERC721;
        address nftAddress;
        address owner;
        address currency; // use zero address or 0xaaa for ETH
        uint256 amount; // amount of NFTs being sold
        uint256 purchased; // amount of NFTs purchased thus far
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    struct AuctionInfo {
        uint128 id; // auctionId
        uint128 nftId;
        bool isERC721;
        address nftAddress;
        address owner; // NFT owner address
        address currency; // use zero address or 0xeee for ETH
        uint256 startTime;
        uint256 endTime;
        uint256 reservePrice; // may need to be made private
    }

    struct Bid {
        uint256 amount;
        uint256 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => SaleInfo) public sales; // saleId => saleInfo
    mapping(uint256 => AuctionInfo) public auctions; // auctionId => AuctionInfo
    mapping(uint256 => bool) public cancelledSale; // saleId => status
    mapping(uint256 => bool) public cancelledAuction; // auctionId => status
    mapping(uint256 => bool) public claimed; // auctionId => status
    mapping(uint256 => address) public highestBidder; // auctionId => highest bidder address
    mapping(address => uint256) public escrow; // currency address => escrow amount

    // saleId => purchaserAddress => amountPurchased
    mapping(uint256 => mapping(address => uint256)) public purchased;
    // auctionId => bidderAddress => Bid
    mapping(uint256 => mapping(address => Bid)) public bids;
    // userAddress => tokenAddress => amount
    mapping(address => mapping(address => uint256)) public claimableFunds;

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address registry) {
        _REGISTRY = IRegistry(registry);
    }

    /*//////////////////////////////////////////////////////////////
                          STATE-CHANGING SALE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a sale of ERC1155 and ERC721 NFTs
    /// @dev NFT contract must be ERC2981-compliant and recognized by Registry
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    /// @param nftAddress the address of the NFT contract
    /// @param nftId the id of the NFTs on the NFT contract
    /// @param startTime uint256 timestamp when the sale should commence
    /// @param endTime uint256 timestamp when sale should end
    /// @param price the price for each NFT
    /// @param currency address of the token bids should be made in
    /// @return saleId the index of the sale being created
    function createSale(
        bool isERC721,
        address nftAddress,
        uint128 nftId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        address currency
    ) external returns (uint256 saleId) {
        _beforeSaleOrAuction(nftAddress, startTime, endTime, currency);
        if (isERC721 && amount != 1) revert CanOnlySellOneNFT();

        INFT nftContract = INFT(nftAddress);

        // transfer nft to the platform
        isERC721
            ? nftContract.safeTransferFrom(msg.sender, address(this), nftId, "")
            : nftContract.safeTransferFrom(
                msg.sender,
                address(this),
                nftId,
                amount,
                ""
            );

        // save the sale info
        unchecked {
            ++saleIdCounter;
        }

        saleId = saleIdCounter;
        sales[saleId] = SaleInfo({
            isERC721: isERC721,
            nftAddress: nftAddress,
            nftId: nftId,
            owner: msg.sender,
            amount: amount,
            purchased: 0,
            startTime: startTime,
            endTime: endTime,
            price: price,
            currency: currency
        });

        emit SaleCreated(saleId, nftAddress, nftId);
    }

    /// @notice Allows purchase of NFTs from a sale
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    /// @dev automatically calculates system fee and royalties (where applicable)
    /// @dev pass in 1 if a user buys ERC 721
    /// @param saleId the index of the sale to purchase from
    /// @param amountToBuy the number of NFTs to purchase
    /// @param amountFromBalance the amount to spend from msg.sender's balance in this contract
    /// @return a bool indicating success
    function buy(
        uint256 saleId,
        address recipient,
        uint256 amountToBuy,
        uint256 amountFromBalance
    ) external payable returns (bool) {
        if (!_REGISTRY.platformContracts(address(this)))
            revert ContractIsDeprecated();
        if (getSaleStatus(saleId) != "ACTIVE") revert SaleIsNotActive();

        assembly {
            if iszero(recipient) {
                let ptr := mload(0x40)
                mstore(
                    ptr,
                    0x8579befe00000000000000000000000000000000000000000000000000000000
                ) // selector for `ZeroAddressNotAllowed()`
                revert(ptr, 0x4)
            }
        }

        SaleInfo memory saleInfo = sales[saleId];
        if (amountToBuy > saleInfo.amount - saleInfo.purchased)
            revert NotEnoughStock();

        address currency = saleInfo.currency;
        if (amountFromBalance > claimableFunds[msg.sender][currency])
            revert NotEnoughBalance();

        INFT nftContract = INFT(saleInfo.nftAddress);

        (address artistAddress, uint256 royalties) = nftContract.royaltyInfo(
            saleInfo.nftId,
            amountToBuy * saleInfo.price
        );

        // send the nft price to the platform
        if (currency != ETH) {
            IERC20 token = IERC20(currency);

            token.safeTransferFrom(
                msg.sender,
                address(this),
                (amountToBuy * saleInfo.price) - amountFromBalance
            );
        } else if (
            msg.value != (amountToBuy * saleInfo.price) - amountFromBalance
        ) revert InputValueAndPriceMismatch();

        if (amountFromBalance != 0) {
            claimableFunds[msg.sender][currency] -= amountFromBalance;
        }

        // system fee
        (address systemWallet, uint256 fee) = _REGISTRY.feeInfo(
            amountToBuy * saleInfo.price
        );
        claimableFunds[systemWallet][currency] += fee;

        // artist royalty if artist isn't the seller
        if (saleInfo.owner != artistAddress) {
            claimableFunds[artistAddress][currency] += royalties;
        } else {
            // since the artist is the seller
            delete royalties;
        }

        // seller gains
        claimableFunds[saleInfo.owner][currency] +=
            (amountToBuy * saleInfo.price) -
            fee -
            royalties;

        // update the sale info
        unchecked {
            sales[saleId].purchased += amountToBuy;
            purchased[saleId][msg.sender] += amountToBuy;
        }

        // send the nft to the buyer
        saleInfo.isERC721
            ? nftContract.safeTransferFrom(
                address(this),
                recipient,
                saleInfo.nftId,
                ""
            )
            : nftContract.safeTransferFrom(
                address(this),
                recipient,
                saleInfo.nftId,
                amountToBuy,
                ""
            );

        emit Purchase(saleId, msg.sender, recipient);
        return true;
    }

    /// @notice Allows seller to reclaim unsold NFTs
    /// @dev sale must be cancelledAuction or ended
    /// @param saleId the index of the sale to claim from
    function claimSaleNfts(uint256 saleId) external {
        bytes32 status = getSaleStatus(saleId);
        if (status != "CANCELLED" && status != "ENDED")
            revert SaleIsNotClosed();

        address nftAddress = sales[saleId].nftAddress;
        uint256 nftId = sales[saleId].nftId;
        uint256 amount = sales[saleId].amount;
        uint256 salePurchased = sales[saleId].purchased;
        address owner = sales[saleId].owner;

        if (msg.sender != owner) revert OnlyNFTOwnerCanClaim();
        if (salePurchased == amount) revert StockAlreadySoldOrClaimed();

        uint256 stock = amount - salePurchased;
        // update the sale info and send the nfts back to the seller
        sales[saleId].purchased = amount;
        sales[saleId].isERC721
            ? INFT(nftAddress).safeTransferFrom(address(this), owner, nftId, "")
            : INFT(nftAddress).safeTransferFrom(
                address(this),
                owner,
                nftId,
                stock,
                ""
            );

        emit ClaimSaleNFTs(saleId, msg.sender, stock);
    }

    /// @notice Withdraws in-contract balance of a particular token
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    function claimFunds(address tokenAddress) external {
        uint256 payout = claimableFunds[msg.sender][tokenAddress];
        if (payout == 0) revert NothingToClaim();

        if (tokenAddress != ETH) {
            delete claimableFunds[msg.sender][tokenAddress];
            IERC20(tokenAddress).safeTransfer(msg.sender, payout);
        } else {
            delete claimableFunds[msg.sender][tokenAddress];

            (bool success, ) = msg.sender.call{value: payout}("");
            // bubble up the error meassage if the transfer fails
            if (!success) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }

        emit ClaimFunds(msg.sender, tokenAddress, payout);
    }

    /// @notice Allows contract owner or seller to cancel a pending or active sale
    /// @param saleId the index of the sale to cancel
    function cancelSale(uint256 saleId) external {
        if (msg.sender != sales[saleId].owner && msg.sender != owner())
            revert OnlyOwnerOrSaleCreator();

        bytes32 status = getSaleStatus(saleId);
        if (status != "ACTIVE" && status != "PENDING")
            revert SaleMustBeActiveOrPending();

        cancelledSale[saleId] = true;

        emit SaleCancelled(saleId);
    }

    /*//////////////////////////////////////////////////////////////
                          STATE-CHANGING AUCTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a first-price auction for a ERC1155 NFT
    /// @dev NFT contract must be ERC2981-compliant and recognized by Registry
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    /// @param nftAddress the address of the NFT contract
    /// @param nftId the id of the NFT on the NFT contract
    /// @param startTime uint256 timestamp when the auction should commence
    /// @param endTime uint256 timestamp when auction should end
    /// @param reservePrice minimum price for bids
    /// @param currency address of the token bids should be made in
    /// @return auctionId the index of the auction being created
    function createAuction(
        bool isERC721,
        address nftAddress,
        uint128 nftId,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice,
        address currency
    ) external returns (uint128 auctionId) {
        _beforeSaleOrAuction(nftAddress, startTime, endTime, currency);
        INFT nftContract = INFT(nftAddress);

        // transfer the nft to the platform
        isERC721
            ? nftContract.safeTransferFrom(msg.sender, address(this), nftId, "")
            : nftContract.safeTransferFrom(
                msg.sender,
                address(this),
                nftId,
                1,
                ""
            );

        // save auction info
        unchecked {
            ++auctionIdCounter;
        }

        auctionId = auctionIdCounter;
        auctions[auctionId] = AuctionInfo({
            isERC721: isERC721,
            id: auctionId,
            owner: msg.sender,
            nftAddress: nftAddress,
            nftId: nftId,
            startTime: startTime,
            endTime: endTime,
            reservePrice: reservePrice,
            currency: currency
        });

        emit NewAuction(auctionId, auctions[auctionId]);
    }

    /// @notice Allows bidding on a specifc auction
    /// @dev use address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa) for ETH
    /// @param auctionId the index of the auction to bid on
    /// @param amountFromBalance the amount to bid from msg.sender's balance in this contract
    /// @param externalFunds the amount to bid from funds in msg.sender's personal balance
    /// @return a bool indicating success
    function bid(
        uint256 auctionId,
        uint256 amountFromBalance,
        uint256 externalFunds
    ) external payable returns (bool) {
        if (!_REGISTRY.platformContracts(address(this)))
            revert ContractIsDeprecated();
        if (getAuctionStatus(auctionId) != "ACTIVE")
            revert AuctionIsNotActive();

        uint256 totalAmount = amountFromBalance +
            externalFunds +
            // this allows the top bidder to top off their bid
            bids[auctionId][msg.sender].amount;

        if (totalAmount <= bids[auctionId][highestBidder[auctionId]].amount)
            revert BidIsNotHighEnough();
        if (totalAmount < auctions[auctionId].reservePrice)
            revert BidLoweThanReservePrice();

        address currency = auctions[auctionId].currency;
        if (amountFromBalance > claimableFunds[msg.sender][currency])
            revert NotEnoughBalance();

        if (currency != ETH) {
            IERC20 token = IERC20(currency);
            token.safeTransferFrom(msg.sender, address(this), externalFunds);
        } else {
            if (msg.value != externalFunds) revert ArgumentsAndValueMismatch();
        }

        // next highest bid can be made claimable now,
        // also helps for figuring out how much more net is in escrow
        address lastHighestBidder = highestBidder[auctionId];
        uint256 lastHighestAmount = bids[auctionId][lastHighestBidder].amount;
        escrow[currency] += totalAmount - lastHighestAmount;

        // last bidder can claim their fund now
        if (lastHighestBidder != msg.sender) {
            delete bids[auctionId][lastHighestBidder].amount;
            claimableFunds[lastHighestBidder][currency] += lastHighestAmount;

            emit BalanceUpdated(
                lastHighestBidder,
                currency,
                claimableFunds[lastHighestBidder][currency]
            );
        }
        if (amountFromBalance != 0) {
            claimableFunds[msg.sender][currency] -= amountFromBalance;

            emit BalanceUpdated(msg.sender, currency, amountFromBalance);
        }

        bids[auctionId][msg.sender].amount = totalAmount;
        bids[auctionId][msg.sender].timestamp = block.timestamp;
        highestBidder[auctionId] = msg.sender;

        emit BidPlaced(auctionId, totalAmount);
        return true;
    }

    /// @notice Send NFT to auction winner and funds to auctioner's balance
    /// @notice Alternatively, allows auctioner to reclaim on an unsuccessful auction
    /// @dev this function delivers the NFT and moves the bid to the auctioner's claimable balance
    ///   and also accounts for the system fee and royalties (if applicable)
    function resolveAuction(uint256 auctionId) external {
        bytes32 status = getAuctionStatus(auctionId);
        if (status != "CANCELLED" && status != "ENDED")
            revert AuctionIsNotEndOrCancelled();

        uint256 nftId = auctions[auctionId].nftId;
        address owner = auctions[auctionId].owner;
        address highestBidder_ = highestBidder[auctionId];
        uint256 winningBid = bids[auctionId][highestBidder_].amount;
        uint256 totalFundsToPay = msg.sender == owner ? 0 : winningBid;
        INFT nftContract = INFT(auctions[auctionId].nftAddress);

        // accounting logic
        address recipient;
        if (totalFundsToPay != 0) {
            _nftPayment(auctionId, winningBid, nftContract);
            recipient = highestBidder_;
        } else {
            recipient = owner;
        }
        auctions[auctionId].isERC721
            ? nftContract.safeTransferFrom(address(this), recipient, nftId, "")
            : nftContract.safeTransferFrom(
                address(this),
                recipient,
                nftId,
                1,
                ""
            );

        claimed[auctionId] = true;

        emit ClaimAuctionNFT(
            auctions[auctionId].id,
            msg.sender,
            recipient,
            bids[auctionId][highestBidder_].amount
        );
    }

    /// @notice Allows contract owner or auctioner to cancel a pending or active auction
    function cancelAuction(uint256 auctionId) external {
        if (msg.sender != auctions[auctionId].owner && msg.sender != owner())
            revert OnlyOwnerOrAuctionCreator();

        bytes32 status = getAuctionStatus(auctionId);
        if (status != "ACTIVE" && status != "PENDING")
            revert AuctionMustBeActiveOrPending();

        cancelledAuction[auctionId] = true;

        address currency = auctions[auctionId].currency;
        address highestBidder_ = highestBidder[auctionId];
        uint256 highestBid = bids[auctionId][highestBidder_].amount;

        // current highest bid moves from escrow to being reclaimable
        escrow[currency] -= highestBid;
        claimableFunds[highestBidder_][currency] += highestBid;

        emit BalanceUpdated(
            highestBidder_,
            currency,
            claimableFunds[highestBidder_][currency]
        );
        emit AuctionCancelled(auctionId);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAuctionStatus(uint256 auctionId) public view returns (bytes32) {
        if (auctionId > auctionIdCounter || auctionId == 0)
            revert AuctionDoesNotExist();

        if (
            cancelledAuction[auctionId] ||
            !_REGISTRY.platformContracts(address(this))
        ) return "CANCELLED";

        if (claimed[auctionId]) return "ENDED & CLAIMED";

        uint256 startTime = auctions[auctionId].startTime;
        uint256 endTime = auctions[auctionId].endTime;

        if (block.timestamp < startTime) return "PENDING";

        if (block.timestamp >= startTime && block.timestamp < endTime)
            return "ACTIVE";

        if (block.timestamp > endTime) return "ENDED";

        revert UnexpectedError();
    }

    function getSaleStatus(uint256 saleId) public view returns (bytes32) {
        if (saleId > saleIdCounter || saleId == 0) revert SaleDoesNotExist();

        if (
            cancelledSale[saleId] || !_REGISTRY.platformContracts(address(this))
        ) return "CANCELLED";

        SaleInfo memory saleInfo = sales[saleId];
        if (block.timestamp < saleInfo.startTime) return "PENDING";

        if (
            block.timestamp < saleInfo.endTime &&
            saleInfo.purchased < saleInfo.amount
        ) return "ACTIVE";

        if (
            block.timestamp >= saleInfo.endTime ||
            saleInfo.purchased == saleInfo.amount
        ) return "ENDED";

        revert UnexpectedError();
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _beforeSaleOrAuction(
        address nftAddress,
        uint256 startTime,
        uint256 endTime,
        address currency
    ) private {
        if (!_REGISTRY.platformContracts(nftAddress))
            revert NFTContractIsNotApproved();
        if (!_REGISTRY.platformContracts(address(this)))
            revert ContractIsDeprecated();
        if (!_REGISTRY.approvedCurrencies(currency))
            revert CurrencyIsNotSupported();
        if (!INFT(nftAddress).supportsInterface(0x2a55205a))
            revert ContractMustSupportERC2981();
        if (endTime <= startTime) revert EndTimeMustBeGreaterThanStartTime();
    }

    /// @notice internal function for handling royalties and system fee
    function _nftPayment(
        uint256 auctionId,
        uint256 fundsToPay,
        INFT nftContract
    ) private {
        address currency = auctions[auctionId].currency;

        escrow[currency] -= fundsToPay;
        // if this is from a successful auction
        (address artistAddress, uint256 royalties) = nftContract.royaltyInfo(
            auctions[auctionId].nftId,
            fundsToPay
        );

        // system fee
        (address systemWallet, uint256 fee) = _REGISTRY.feeInfo(fundsToPay);
        unchecked {
            fundsToPay -= fee;
        }
        claimableFunds[systemWallet][currency] += fee;

        emit BalanceUpdated(
            systemWallet,
            currency,
            claimableFunds[systemWallet][currency]
        );

        // artist royalty if artist isn't the seller
        if (auctions[auctionId].owner != artistAddress) {
            unchecked {
                fundsToPay -= royalties;
            }
            claimableFunds[artistAddress][currency] += royalties;

            emit BalanceUpdated(
                artistAddress,
                currency,
                claimableFunds[artistAddress][currency]
            );
        }

        // seller gains
        claimableFunds[auctions[auctionId].owner][
            auctions[auctionId].currency
        ] += fundsToPay;

        emit BalanceUpdated(
            auctions[auctionId].owner,
            auctions[auctionId].currency,
            claimableFunds[auctions[auctionId].owner][
                auctions[auctionId].currency
            ]
        );
    }
}

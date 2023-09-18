// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

/// @title An ERC721 token marketplace
/// @author Clyde D'Cruz
/// @notice You can use this contract as an NFT auction marketplace for any ERC721 complaint token.
contract ERC721MarketPlace {
    enum NftSaleStatus {
        ACTIVE,
        ENDED
    }
    enum NftSaleEventType {
        SALE_CREATED,
        BID_CREATED,
        SALE_ENDED,
        NFT_CLAIMED
    }

    struct NftSale {
        address poster;
        uint256 item;
        uint256 minBidPrice;
        uint256 saleEndTime;
        address highestBidder;
        uint256 highestBid;
        NftSaleStatus status;
        bool isValid;
    }

    IERC721 internal nftTokenContract;

    mapping(address => uint256) internal pendingRefunds;

    mapping(uint256 => NftSale) internal sales;

    uint256 internal saleCounter;

    event NftSaleEvent(uint256 saleId, NftSaleEventType eventType);
    event BidRefundEvent(address beneficiary, uint256 refundAmount);

    constructor(address _nftContractAddress) {
        nftTokenContract = IERC721(_nftContractAddress);
    }

    // external functions

    /// @notice Lets a user bid for a particular NFT sale
    /// @dev The caller must include the ether in the 'value' part of the transaction while executing a bid transaction.
    /// @param saleId The uint256 ID of the sale for which the user can bid on
    function bidForSale(uint256 saleId) external payable {
        NftSale memory previousBidData;
        // check if sale is proper
        NftSale memory sale = validateSale(saleId);
        previousBidData = sale;
        // Revert the call if the auction period is over.
        require(block.timestamp <= sale.saleEndTime, "Auction already ended.");

        // check price
        require(
            msg.value > sale.highestBid && msg.value >= sale.minBidPrice,
            "Bid should be higher than min bid price and existing highest bid"
        );

        sale.highestBid = msg.value;
        sale.highestBidder = msg.sender;
        sales[saleId] = sale;

        // refund ether of previous bidder
        if (previousBidData.highestBid > 0) {
            pendingRefunds[previousBidData.highestBidder] = previousBidData
                .highestBid;
        }
        emit NftSaleEvent(saleId, NftSaleEventType.BID_CREATED);
    }

    /// @notice Creates a limited time auction for a specified NFT
    /// @dev The caller must approve transfer of this NFT to this contract address before calling this function.
    ///      Overflow of minBidPrice (though highly improbably) would already be checked by compiler for this version of solidity.
    /// @param listedNftIdentifier The uint256 ID of the NFT that is to be sold
    /// @param minBidPrice The minimum bid pice in ether.
    /// @param saleTimePeriod Time in seconds after which this sale will end. Time is considered from current block time
    function createSale(
        uint256 listedNftIdentifier,
        uint256 minBidPrice,
        uint256 saleTimePeriod
    ) external {
        // validate sale end time
        // validate min bid price

        // transfer ownership of NFT to this contract address
        nftTokenContract.transferFrom(
            msg.sender,
            address(this),
            listedNftIdentifier
        );

        // construct sale
        sales[saleCounter] = NftSale(
            msg.sender,
            listedNftIdentifier,
            minBidPrice,
            block.timestamp + saleTimePeriod,
            address(0),
            0,
            NftSaleStatus.ACTIVE,
            true
        );
        saleCounter += 1;

        // emit event for created sale
        emit NftSaleEvent(saleCounter - 1, NftSaleEventType.SALE_CREATED);
    }

    /// @notice Lets a user claim a refund for a bid that is no longer the highest bid
    /// @dev This function uses the Withdrawal pattern as decribed in solidity docs
    function claimBidRefund() external {
        uint256 amount = pendingRefunds[msg.sender];
        pendingRefunds[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BidRefundEvent(msg.sender, amount);
    }

    /// @notice Lets the sale poster end the sale after the sufficient time has elapsed. This only marks the sale complete.
    ///         The highest bidder will then need to claim the NFT
    /// @param saleId The uint256 ID of the sale to be ended
    function endSale(uint256 saleId) external {
        // check if sale is proper
        NftSale memory sale = validateSale(saleId);

        // only sale poster should be allowed to call this
        require(msg.sender == sale.poster, "Caller is not the sale poster");

        _endSale(sale, saleId);
    }

    /// @notice Lets the highest bidder claim thier NFT, or in case not bids were recieved it lets the poster claim teh NFT
    /// @dev Highest bidder needs to expend gas to claim thier NFT. This internally also closes the sale if not closed yet.
    /// @param saleId The uint256 ID of the relevant sale
    function claimNft(uint256 saleId) external {
        // check if sale is proper
        NftSale memory sale = validateSale(saleId);

        address nftBeneficiary;
        if (sale.highestBid == 0) {
            // if the auction expired without any bids, poster should be allowed to claim teh NFT back
            require(sale.poster == msg.sender, "Caller is not the sale poster");
            nftBeneficiary = sale.poster;
        } else {
            // only highest bidder should be allowed to call this
            require(
                sale.highestBidder == msg.sender,
                "Caller is not the highest bidder"
            );
            nftBeneficiary = sale.highestBidder;
        }

        if (sale.status == NftSaleStatus.ACTIVE) {
            _endSale(sale, saleId);
        }

        // transfer Nft to highest bidder
        nftTokenContract.transferFrom(address(this), nftBeneficiary, sale.item);

        emit NftSaleEvent(saleId, NftSaleEventType.NFT_CLAIMED);
    }

    // External view functions

    /// @notice Lets a user view details of a particular sale
    /// @param saleId The uint256 ID of the sale
    /// @return The NftSale object corresponding to the given saleId
    function getSale(uint256 saleId) external view returns (NftSale memory) {
        return validateSale(saleId);
    }

    /// @notice Returns a list of all sales
    /// @return An array of NftSale objects
    function getSales() external view returns (NftSale[] memory) {
        NftSale[] memory saleArray = new NftSale[](saleCounter);
        for (uint256 saleId = 0; saleId < saleCounter; saleId++) {
            saleArray[saleId] = sales[saleId];
        }
        return saleArray;
    }

    // Internal functions

    /// @dev Internal utility function that does necessary operations to end a sale
    /// @param sale The sale object
    /// @param saleId The uint256 ID of the sale
    function _endSale(NftSale memory sale, uint256 saleId) internal {
        // Sale should be in active state when this call is made
        require(sale.status == NftSaleStatus.ACTIVE, "Sale not active");

        // Revert the call if the auction period is not over.
        require(block.timestamp > sale.saleEndTime, "Auction not yet ended");

        NftSale memory endedSale = sale;

        // end sale
        endedSale.status = NftSaleStatus.ENDED;

        sales[saleId] = endedSale;
        emit NftSaleEvent(saleId, NftSaleEventType.SALE_ENDED);
    }

    // Internal view functions

    /// @dev Thsi is an internal function used to check if a sale object is a valid one i.e. properly initialized
    /// @param saleId The uint256 ID of the sale
    /// @return The NftSale object corresponding to the given saleId
    function validateSale(uint256 saleId)
        internal
        view
        returns (NftSale memory)
    {
        NftSale memory sale = sales[saleId];
        require(sale.isValid, "Sale is not valid");
        return sale;
    }
}

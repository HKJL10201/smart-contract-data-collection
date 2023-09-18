// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {AssetType, Action} from "./lib/Structs.sol";
import "./lib/OrderEncoder.sol";
import "./interfaces/ITransferHelper.sol";
import "./lib/SignatureVerifier.sol";
import "./lib/UpgradeableContract.sol";
import "./interfaces/IPolarysExchange.sol";

contract PolarysExchange is
    IPolarysExchange,
    OrderEncoder,
    ReentrancyGuard,
    UpgradeableContract
{
    using SafeMath for uint256;

    /* Store orders and data */
    mapping(address => mapping(uint256 => bytes32)) private tokenOrder;
    mapping(bytes32 => bool) private orderFilled;

    mapping(bytes32 => address) private highestBidder;
    mapping(bytes32 => uint256) private highestBid;
    mapping(bytes32 => uint256) private auctionExpirationTime;

    /* TransferHelper Address */
    ITransferHelper public TransferHelper;
    address public feeRecipient; //feeAddress

    string public constant EXCHANGE_NAME = "TAGWEB3";
    string public constant VERSION = "1.0.0";

    bool private safe;
    uint8 public feeRate;

    uint256 public ordersFilled;

    constructor() UpgradeableContract(address(this), msg.sender) {}

    modifier isSecure() {
        require(safe, "insecure call");
        _;
        safe = false;
    }

    modifier notZero() {
        require(msg.value != 0);
        _;
    }

    /* Order Events */
    event OrderCreated(
        address indexed seller,
        address paymentToken,
        address collection,
        uint256 indexed tokenId,
        bytes32 orderHash,
        Order order
    );
    event OrderCanceled(bytes32 orderHash);
    event OrderFilled(
        address indexed seller,
        address indexed buyer,
        address collection,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price,
        bytes32 orderHash
    );

    /* Auction Events */
    event AuctionCreated(
        address indexed seller,
        address paymentToken,
        address collection,
        uint256 indexed tokenId,
        bytes32 orderHash,
        Auction auction
    );
    event NewBidPlaced(
        address indexed seller,
        address indexed bidder,
        address paymentToken,
        uint256 highestBid,
        address collection,
        uint256 indexed tokenId,
        bytes32 orderHash
    );
    event AuctionCanceled(bytes32 orderHash);
    event AuctionCompleted(
        address indexed seller,
        address indexed highestBidder,
        address collection,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 highestBid,
        bytes32 orderHash
    );

    /**
     * @dev Updates the address of the Transfer Helper contract.
     *      Only the contract administrator can perform this action.
     * @param _transferHelper The address of the new Transfer Helper contract.
     */
    function updateTransferHelper(address _transferHelper) public onlyAdmin {
        TransferHelper = ITransferHelper(_transferHelper);
    }

    /**
     * @dev Execute a sell order or cancel an existing order.
     * @param order The order to be executed or canceled.
     * @param _signature Signature for order verification.
     */
    function executeSellOrCancel(
        Order calldata order,
        bytes memory _signature
    ) external nonReentrant {
        // Compute the hash of the order for verification
        bytes32 orderHash;
        if(order.action == Action.SELL){
            orderHash = _hashOrder(order);
        } else if(order.action == Action.CANCEL){
            orderHash = _orderActive(order.collection, order.tokenId);
        }

        // Verify the provided signature against the order hash and the sender's address
        require(
            SignatureVerifier.verifySignature(
                orderHash,
                _signature,
                msg.sender
            ),
            "Polarys Exchange: Invalid signature for order execution"
        );

        // Verify that the caller is the owner of the token and it is approved for transfer
        require(
            _ownerAndApprovalVerify(order.collection, order.tokenId),
            "Polarys Exchange: You are not the owner or token not approved"
        );

        // Set the safe flag to true before executing the operation
        safe = true;

        // Execute the sell or cancel operation based on the order action
        _executeSellOrCancel(order, orderHash);
    }

    /**
     * @dev Verifies if the caller has approval for the token and is its owner.
     * @param collection Address of the token collection (ERC721 contract).
     * @param tokenId ID of the token to be verified.
     * @return A boolean indicating if the caller has ownership and approval.
     */
    function _ownerAndApprovalVerify(
        address collection,
        uint256 tokenId
    ) private view returns (bool) {
        // Check if the caller has approval for the token and is its owner
        return (_verifyTokenApproval(collection, tokenId) &&
            _validateOwnership(collection, tokenId));
    }

    /**
     * @dev Execute a sell or cancel action for an order.
     * @param order The order containing the action and order details.
     * @param orderHash The unique hash representing the order.
     */
    function _executeSellOrCancel(
        Order calldata order,
        bytes32 orderHash
    ) public isSecure {
        if (order.action == Action.SELL) {
            require(
                _orderActive(order.collection, order.tokenId) == 0,
                "Polarys Exchange: token already on sale"
            );
            _storeData(order.collection, order.tokenId, orderHash);

            emit OrderCreated(
                msg.sender,
                order.paymentToken,
                order.collection,
                order.tokenId,
                orderHash,
                order
            );
        } else if (order.action == Action.CANCEL) {
            delete tokenOrder[order.collection][order.tokenId];

            emit OrderCanceled(orderHash);
        }
    }

    /**
     * @dev Execute a buy order.
     * @param order Order details including asset, collection, tokenId, etc.
     * @param orderHash Hash of the order for verification.
     * @param _signature Signature for order execution.
     * @notice Requires valid signature and order parameters.
     * @notice Requires the order to be verified against the given order hash.
     * @notice Marks the execution as secure.
     */
    function executeBuy(
        Order calldata order,
        bytes32 orderHash,
        bytes memory _signature
    ) external payable notZero nonReentrant {
        require(
            SignatureVerifier.verifySignature(
                orderHash,
                _signature,
                msg.sender
            ),
            "Polarys Exchange: Invalid signature for order execution"
        );
        require(
            _verifyOrdersByTokenId(order, orderHash),
            "Polarys Exchange: Invalid order paremeters"
        );

        safe = true;

        _executeBuy(order, orderHash);
    }

    /**
     * @dev Execute a purchase order
     * @param order Order details
     * @param orderHash Hash of the order
     */
    function _executeBuy(
        Order calldata order,
        bytes32 orderHash
    ) public payable isSecure {
        _transferAssets(
            order.asset,
            order.collection,
            order.seller,
            order.buyer,
            order.tokenId,
            order.tokenAmount
        );

        _transferFunds(order.seller, order.price);

        delete tokenOrder[order.collection][order.tokenId];
        orderFilled[orderHash] = true;

        emit OrderFilled(
            order.seller,
            msg.sender,
            order.collection,
            order.tokenId,
            order.paymentToken,
            order.price,
            orderHash
        );

        _addFilledOrders();
    }

    /**
     * @dev Executes a buy order using ERC20 tokens as payment.
     * @param order The buy order details.
     * @param orderHash The hash of the buy order.
     * @param _signature The signature for order execution.
     * @notice Requires a valid payment token, valid signature, and order parameters.
     * @notice Must be called externally and not during a reentrant call.
     */
    function executeBuyWithERC20(
        Order calldata order,
        bytes32 orderHash,
        bytes memory _signature
    ) external nonReentrant {
        require(
            order.paymentToken != address(0),
            "Polarys Exchange: Invalid payment token"
        );

        require(
            SignatureVerifier.verifySignature(
                orderHash,
                _signature,
                msg.sender
            ),
            "Polarys Exchange: Invalid signature for order execution"
        );

        require(
            _verifyOrdersByTokenId(order, orderHash),
            "Polarys Exchange: Invalid order parameters"
        );

        safe = true;

        _executeBuyWithERC20(order, orderHash);
    }

    /**
     * @dev Execute a buy order using ERC20 payment.
     * Transfers the asset from seller to buyer, and the specified ERC20 payment token from buyer to seller.
     * Deletes the order and emits an OrderFilled event.
     * @param order The order to execute.
     * @param orderHash The hash of the order.
     */
    function _executeBuyWithERC20(
        Order calldata order,
        bytes32 orderHash
    ) public isSecure {
        // Transfer the asset (ERC721 or ERC1155 tokens) from seller to buyer
        _transferAssets(
            order.asset,
            order.collection,
            order.seller,
            order.buyer,
            order.tokenId,
            order.tokenAmount
        );

        // Transfer the specified ERC20 payment token from the buyer to the seller
        _transferERC20(
            order.paymentToken,
            msg.sender,
            order.seller,
            order.price
        );

        // Remove the order from the tokenOrder mapping
        delete tokenOrder[order.collection][order.tokenId];

        // Emit an OrderFilled event to indicate successful execution
        emit OrderFilled(
            order.seller,
            msg.sender,
            order.collection,
            order.tokenId,
            order.paymentToken,
            order.price,
            orderHash
        );

        // Increment the count of filled orders
        _addFilledOrders();
    }

    function _ordersFilled(bytes32 orderHash) public view returns (bool) {
        return (orderFilled[orderHash]);
    }

    /**
     * @dev Executes an auction based on the provided auction parameters and signature.
     * @param auction The auction parameters including collection, tokenId, and action.
     * @param _signature The signature to verify the authenticity of the auction parameters.
     * if the signature is invalid or the sender is not the owner or token is not approved.
     */
    function executeAuction(
        Auction calldata auction,
        bytes memory _signature
    ) public nonReentrant {
        // Generate the order hash from the auction parameters
        bytes32 orderHash;
        if(auction.action == Action.CLAIM){
            orderHash = _orderActive(auction.collection, auction.tokenId);
        } else {
            orderHash = _hashAuction(auction);
        }

        // Verify the signature of the order hash
        require(
            SignatureVerifier.verifySignature(
                orderHash,
                _signature,
                msg.sender
            ),
            "Polarys Exchange: Invalid signature for order execution"
        );

        // Verify that the caller is the owner of the token and it is approved for transfer
        require(
            _ownerAndApprovalVerify(auction.collection, auction.tokenId) || msg.sender == _highestBidder(orderHash),
            "Polarys Exchange: You are not the owner or token not approved"
        );

        // Mark the execution as safe
        safe = true;

        // Execute the auction
        _executeAuction(auction, orderHash);
    }

    /**
     * @dev Execute an auction based on the provided auction details and order hash.
     * @param auction Auction details containing the action type, collection, token ID, and more.
     * @param orderHash Hash of the associated order.
     */
    function _executeAuction(
        Auction calldata auction,
        bytes32 orderHash
    ) public isSecure {
        if (auction.action == Action.RESERVED_PRICE) {
            require(
                _orderActive(auction.collection, auction.tokenId) == 0 &&
                    auction.expirationTime == 0,
                "Polarys Exchange: token already on sale"
            );
            _storeData(auction.collection, auction.tokenId, orderHash);

            emit AuctionCreated(
                msg.sender,
                auction.paymentToken,
                auction.collection,
                auction.tokenId,
                orderHash,
                auction
            );
        } else if (auction.action == Action.CLAIM) {
            bytes32 _orderHash = _orderActive(
                auction.collection,
                auction.tokenId
            );
            require(
                _verifyAuction(auction.expirationTime, orderHash, auction.collection, auction.tokenId),
                "Polarys Exchange: Auction has not ended or invalid caller"
            );

            _transferAssets(
                auction.asset,
                auction.collection,
                auction.seller,
                _highestBidder(_orderHash),
                auction.tokenId,
                auction.tokenAmount
            );

            _transferBack(
                auction.paymentToken,
                auction.seller,
                _highestBid(_orderHash)
            );

            delete tokenOrder[auction.collection][auction.tokenId];
            delete highestBidder[_orderHash];
            delete highestBid[_orderHash];
            delete auctionExpirationTime[_orderHash];
            orderFilled[_orderHash] = true;

            emit AuctionCompleted(
                auction.seller,
                _highestBidder(_orderHash),
                auction.collection,
                auction.tokenId,
                auction.paymentToken,
                _highestBid(_orderHash),
                _orderHash
            );

            emit OrderFilled(
                auction.seller,
                _highestBidder(_orderHash),
                auction.collection,
                auction.tokenId,
                auction.paymentToken,
                _highestBid(_orderHash),
                _orderHash
            );

            _addFilledOrders();
        } else {
            bytes32 _orderHash = _orderActive(
                auction.collection,
                auction.tokenId
            );
            require(
                _highestBidder(_orderHash) == address(0) &&
                    _highestBid(_orderHash) == 0,
                "Polarys Exchange: Auction has started"
            );

            delete tokenOrder[auction.collection][auction.tokenId];

            emit AuctionCanceled(orderHash);
        }
    }

    function _verifyAuction(
        uint256 expirationTime,
        bytes32 orderHash,
        address collection, 
        uint256 tokenId
    ) private view returns (bool) {
        return (expirationTime < block.timestamp
        && msg.sender == _highestBidder(orderHash) || 
        _validateOwnership(collection, tokenId));
    }

    /**
     * @dev Execute a bid in an auction.
     * @param auction The auction details.
     * @param orderHash Hash of the auction order.
     * @param _signature Signature for authentication.
     */
    function executeBid(
        Auction calldata auction,
        bytes32 orderHash,
        bytes memory _signature
    ) external payable notZero nonReentrant {
        // Verify the signature of the auction execution.
        require(
            SignatureVerifier.verifySignature(
                orderHash,
                _signature,
                msg.sender
            ),
            "Polarys Exchange: Invalid signature for auction execution"
        );

        // Verify the validity of auction parameters.
        require(
            _verifyAuctionsByTokenId(auction, orderHash),
            "Polarys Exchange: Invalid auction parameters"
        );

        if(_highestBidder(orderHash) != address(0)){
            require(_expirationTime(orderHash) > block.timestamp, "Polarys Exchange: Auction expired");
        }

        // Mark the execution as safe.
        safe = true;

        // Execute the bid in the auction.
        _executeBid(auction, orderHash);
    }

    /**
     * @dev Executes a bid in an auction.
     * @param auction The auction details.
     * @param orderHash The unique hash identifying the auction order.
     */
    function _executeBid(
        Auction calldata auction,
        bytes32 orderHash
    ) public payable isSecure {
        if (
            _highestBidder(orderHash) != address(0) &&
            _highestBid(orderHash) != 0
        ) {
            // Existing bid present
            address previousBidder = _highestBidder(orderHash);
            uint256 previousBid = _highestBid(orderHash);
            uint256 requiredBid = previousBid.mul(2).div(100);
            require(
                msg.value > requiredBid && auction.highestBid > requiredBid,
                "Polarys Exchange: Minimum required 2% more than current highest bid"
            );
            safeSendETH(previousBidder, previousBid);

            // Update bid information
            highestBidder[orderHash] = msg.sender;
            highestBid[orderHash] = msg.value;
        } else {
            // New bid with no existing bids
            auctionExpirationTime[orderHash] = _calculateAuctionEndTime();
            //auctionExpirationTime[orderHash] = block.timestamp + 480; // Test 
            highestBidder[orderHash] = msg.sender;
            highestBid[orderHash] = msg.value;
        }

        // Emit bid event
        emit NewBidPlaced(
            auction.seller,
            msg.sender,
            auction.paymentToken,
            auction.highestBid,
            auction.collection,
            auction.tokenId,
            orderHash
        );
    }

    /**
     * @dev Execute a bid using ERC20 tokens in an auction.
     * @param auction The auction details.
     * @param orderHash The hash of the auction order.
     * @param _signature The signature for order execution.
     * @dev This function allows users to place bids in an auction using ERC20 tokens.
     *      It verifies the auction parameters, the signature, and the availability of ERC20 tokens.
     *      If the bid is valid, the auction is executed.
     */
    function executeBidWithERC20(
        Auction calldata auction,
        bytes32 orderHash,
        bytes memory _signature
    ) external nonReentrant {
        require(
            auction.paymentToken != address(0),
            "Polarys Exchange: Invalid ERC20"
        );
        require(
            SignatureVerifier.verifySignature(
                orderHash,
                _signature,
                msg.sender
            ),
            "Polarys Exchange: Invalid signature for order execution"
        );
        require(
            _verifyAuctionsByTokenId(auction, orderHash),
            "Polarys Exchange: Order canceled or filled"
        );

        if(_highestBidder(orderHash) != address(0)){
            require(_expirationTime(orderHash) > block.timestamp, "Polarys Exchange: Auction expired");
        }

        safe = true;

        _executeBidWithERC20(auction, orderHash);
    }

    /**
     * @dev Executes a bid in an ERC20-based auction.
     * @param auction The details of the auction.
     * @param orderHash The hash of the auction order.
     * Emits a `NewBidPlaced` event.
     */
    function _executeBidWithERC20(
        Auction calldata auction,
        bytes32 orderHash
    ) public isSecure {
        if (
            _highestBidder(orderHash) != address(0) &&
            _highestBid(orderHash) != 0 // New update: check if auction not has started
        ) {
            address previousBidder = _highestBidder(orderHash);
            uint256 previousBid = _highestBid(orderHash);
            uint256 requiredBid = previousBid.mul(2).div(100);
            require(
                auction.highestBid > requiredBid,
                "Polarys Exchange: Minimum required 2% more than current Bid"
            );

            TransferHelper.executeERC20TransferBack(
                auction.paymentToken,
                previousBidder,
                previousBid
            );

            highestBidder[orderHash] = msg.sender;
            highestBid[orderHash] = auction.highestBid;
        } else {
            // New Update: avoid recalculating end time
            TransferHelper.executeERC20Transfer(
                auction.paymentToken,
                msg.sender,
                address(this),
                auction.highestBid
            );
            auctionExpirationTime[orderHash] = _calculateAuctionEndTime();
            highestBidder[orderHash] = msg.sender;
            highestBid[orderHash] = auction.highestBid;
        }

        emit NewBidPlaced(
            auction.seller,
            msg.sender,
            auction.paymentToken,
            auction.highestBid,
            auction.collection,
            auction.tokenId,
            orderHash
        );
    }

    /**
     * @dev Get the address of the highest bidder for a specific order hash.
     * @param orderHash The hash of the order associated with the auction.
     * @return Address of the highest bidder.
     */
    function _highestBidder(bytes32 orderHash) public view returns (address) {
        return highestBidder[orderHash];
    }

    function _storeData(
        address collection,
        uint256 tokenId,
        bytes32 orderHash
    ) private isSecure {
        tokenOrder[collection][tokenId] = orderHash;
    }

    /**
     * @dev Returns the highest bid amount for a specific order hash.
     * @param orderHash The unique identifier of the order.
     * @return The highest bid amount for the given order hash.
     */
    function _highestBid(bytes32 orderHash) public view returns (uint256) {
        return highestBid[orderHash];
    }

    function _transferBack(
        address paymentToken,
        address to,
        uint256 amount
    ) internal {
        uint256 feeAmount = amount.mul(feeRate).div(100);

        if (paymentToken != address(0)) {
            TransferHelper.executeERC20TransferBack(
                paymentToken,
                to,
                amount.sub(feeAmount)
            );
            TransferHelper.executeERC20TransferBack(
                paymentToken,
                feeRecipient,
                feeAmount
            );
        } else {
            safeSendETH(to, amount.sub(feeAmount));
            safeSendETH(feeRecipient, feeAmount);
        }
    }

    /**
     * @dev Get the expiration time for an order.
     * @param orderHash The unique hash of the order.
     * @return The expiration time of the order.
     */
    function _expirationTime(bytes32 orderHash) public view returns (uint256) {
        return auctionExpirationTime[orderHash];
    }

    function _verifyOrdersByTokenId(
        Order calldata order,
        bytes32 orderHash
    ) internal view returns (bool) {
        return (order.seller != address(0) &&
            order.seller != order.buyer &&
            order.expirationTime > block.timestamp &&
            orderHash == _orderActive(order.collection, order.tokenId) &&
            order.expirationTime > block.timestamp &&
            !_validateOwnership(order.collection, order.tokenId)); //New Update
    }

    function _orderActive(
        address collection,
        uint256 tokenId
    ) private view returns (bytes32) {
        return (tokenOrder[collection][tokenId]);
    }

    function _transferFunds(address seller, uint256 amount) public payable {
        uint256 feeAmount = amount.mul(feeRate).div(100);
        payable(seller).transfer(amount.sub(feeAmount));
        //New Update: No transfer if is address zero
        if (feeRecipient != address(0)) {
            payable(feeRecipient).transfer(feeAmount);
        }
    }

    function _transferERC20(
        address paymentToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 feeAmount = amount.mul(feeRate).div(100);
        TransferHelper.executeERC20Transfer(
            paymentToken,
            from,
            to,
            amount.sub(feeAmount)
        );
        //New Update: Avoid revert transfer to address zero
        if (feeRecipient != address(0)) {
            TransferHelper.executeERC20Transfer(
                paymentToken,
                from,
                feeRecipient,
                feeAmount
            );
        }
    }

    function _transferAssets(
        AssetType asset,
        address collection,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 tokenAmount
    ) internal {
        if (asset == AssetType.ERC721) {
            TransferHelper.executeERC721Transfer(
                collection,
                seller,
                buyer,
                tokenId
            );
        } else if (asset == AssetType.ERC1155) {
            TransferHelper.executeERC1155Transfer(
                collection,
                seller,
                buyer,
                tokenId,
                tokenAmount
            );
        }
    }

    function _verifyAuctionsByTokenId(
        Auction memory auction,
        bytes32 orderHash
    ) internal view returns (bool) {
        return (
            //Check if the owner not is zero address
            (auction.seller != address(0) &&
            //seller can't place a bid
            auction.seller != auction.highestBidder &&
            //Check if the auction is correct
            orderHash == _orderActive(auction.collection, auction.tokenId) &&
            //check if no change the time expiration
            auction.expirationTime == _expirationTime(orderHash) &&
            //check twice if bidder not is the owner
            !_validateOwnership(auction.collection, auction.tokenId)));
    }

    function safeSendETH(address recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Polarys Exchange: Insufficient contract balance"
        );

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Polarys Exchange: Failed to send ETH");
    }

    function _calculateAuctionEndTime() internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + 86400; // 86400 seconds in 24 hours
        return endTime;
    }

    function _validateOwnership(
        address collection_,
        uint256 tokenId_
    ) internal view returns (bool) {
        return IERC721(collection_).ownerOf(tokenId_) == msg.sender;
    }

    /**
     * @dev Update the fee rate and fee recipient address.
     * @param newAddr The new address to receive fees.
     * @param newRate The new fee rate as a percentage.
     * Requirements:
     * - Caller must have administrative privileges.
     */
    function updateFeeRateAndFeeRecipient(
        address newAddr,
        uint8 newRate
    ) external onlyAdmin {
        feeRate = newRate;
        feeRecipient = newAddr;
    }

    function _addFilledOrders() private {
        ordersFilled++;
    }

    function _verifyTokenApproval(
        address _collection,
        uint256 _tokenId
    ) private view returns (bool) {
        IERC721 collection = IERC721(_collection);
        return (collection.getApproved(_tokenId) == address(TransferHelper) ||
            collection.isApprovedForAll(msg.sender, address(TransferHelper)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Types.sol";

/**
 *
 *       ,---,.     ,---,    ,--,     ,--,
 *     ,'  .'  \  .'  .' `\  |'. \   / .`|
 *   ,---.' .' |,---.'     \ ; \ `\ /' / ;
 *   |   |  |: ||   |  .`\  |`. \  /  / .'
 *   :   :  :  /:   : |  '  | \  \/  / ./
 *   :   |    ; |   ' '  ;  :  \  \.'  /
 *   |   :     \'   | ;  .  |   \  ;  ;
 *   |   |   . ||   | :  |  '  / \  \  \
 *   '   :  '; |'   : | /  ;  ;  /\  \  \
 *   |   |  | ; |   | '` ,/ ./__;  \  ;  \
 *   |   :   /  ;   :  .'   |   : / \  \  ;
 *   |   | ,'   |   ,.'     ;   |/   \  ' |
 *   `----'     '---'       `---'     `--`
 *  BDX Smart Contract
 */

contract BigDataAuctionImpl is ReentrancyGuard {
    using Address for address;
    AuctionState public auctionState;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public price;
    //unit GiB: 1 TiB = 1024 GiB
    uint256 public size;
    int8 public version = 7;

    address[] public bidders;
    mapping(address => Bid) public bids;
    mapping(AuctionState => uint256) public times;

    address public admin;
    address public client;

    IEventBus private eventBus;
    IERC20 private paymentToken;
    address public offerManager;
    address public factory;

    string public metaUri;

    uint256[50] internal _gap;

    event BidPlaced(
        address indexed _bidder,
        uint256 _value,
        BidState _bidState,
        BidType _bidType
    );
    event BiddingEnded();
    event BidSelected(address indexed _bidder, uint256 _value);
    event BidCancelled(address indexed _bidder);
    event AuctionCancelled();
    event AuctionCancelledNoBids();
    event BidsUnselectedRefunded(uint32 _count);
    event BidDealSuccessfulPaid(
        address indexed _bidder,
        uint256 _value,
        bool finished
    );
    event BidDealUnsuccessfulRefund(
        address indexed _bidder,
        uint256 _refundAmount,
        uint256 _paidAmount
    );
    event AuctionEnded();

    constructor() {}

    // SPs place bid
    //_bid is a total amount, inclulding the amount bidded
    function placeBid(
        uint256 _bid,
        BidType _bidType
    ) public payable notExpired nonReentrant {
        require(!msg.sender.isContract(), "not allowed contract");
        require(auctionState == AuctionState.BIDDING, "Auction not BIDDING");
        require(_bid >= 0, "Bid not >= 0");
        if (_bidType == BidType.BUY_NOW) {
            require(msg.value == _bid, "Insufficient payment");
        } else {
            require(getAllowance(msg.sender) >= _bid, "Insufficient allowance");
            require(
                paymentToken.balanceOf(msg.sender) >= _bid,
                "Insufficient balance"
            );
        }
        if (!hasBidded(msg.sender)) {
            bidders.push(msg.sender);
        }
        handleBid(_bid, _bidType);
    }

    function endBidding() public onlyClientOrAdmin {
        require(auctionState == AuctionState.BIDDING, "Auction not BIDDING");
        emitEvents("EndBidding");
        for (uint8 i = 0; i < bidders.length; i++) {
            Bid storage b = bids[bidders[i]];
            if (b.bidState != BidState.CANCELLED) {
                updateState(AuctionState.SELECTION);
                updateAllOngoingBidsToPending();
                emit BiddingEnded();
                return;
            }
        }
        updateState(AuctionState.NO_BID_CANCELLED);
        emit AuctionCancelledNoBids();
    }

    //Client select normal bid
    function selectBid(
        address selectedAddress
    ) public onlyClientOrAdmin nonReentrant {
        require(
            auctionState == AuctionState.SELECTION,
            "Auction not SELECTION"
        );
        Bid storage b = bids[selectedAddress];
        require(
            b.bidState == BidState.PENDING_SELECTION,
            "Bid not PENDING_SELECTION"
        );
        require(
            paymentToken.allowance(selectedAddress, address(this)) >=
                b.bidAmount,
            "Insufficient allowance"
        );
        require(
            paymentToken.balanceOf(selectedAddress) >= b.bidAmount,
            "Insufficient balance"
        );
        b.bidState = BidState.SELECTED;
        paymentToken.transferFrom(selectedAddress, address(this), b.bidAmount);
        // only 1 winner.
        refundUnsuccessfulBids();
        updateState(AuctionState.VERIFICATION);
        emitEvents("BidSelected");
        emit BidSelected(selectedAddress, b.bidAmount);
    }

    //auto ends the selection phase
    function endSelection() public onlyClientOrAdmin {
        require(
            auctionState == AuctionState.SELECTION,
            "Auction not SELECTION"
        );
        // auto select the highest one.
        uint256 highest = 0;
        address winner = bidders[0];
        for (uint8 i = 0; i < bidders.length; i++) {
            Bid storage b = bids[bidders[i]];
            if (
                b.bidAmount > highest &&
                b.bidState == BidState.PENDING_SELECTION
            ) {
                highest = b.bidAmount;
                winner = bidders[i];
            }
        }
        selectBid(winner);
    }

    function cancelAuction() public onlyClientOrAdmin {
        require(
            auctionState == AuctionState.BIDDING ||
                auctionState == AuctionState.SELECTION,
            "Auction not BIDDING/SELECTION"
        );
        updateState(AuctionState.CANCELLED);
        refundUnsuccessfulBids();
        emitEvents("AuctionCancelled");
        emit AuctionCancelled();
    }

    function cancelBid() public {
        require(
            auctionState == AuctionState.BIDDING ||
                auctionState == AuctionState.SELECTION,
            "Auction not BIDDING/SELECTION"
        );
        require(hasBidded(msg.sender), "not bidded");
        Bid storage b = bids[msg.sender];
        require(
            b.bidState == BidState.BIDDING ||
                b.bidState == BidState.PENDING_SELECTION,
            "Not BIDDING/SELECTION"
        );
        b.bidState = BidState.CANCELLED;
        emit BidCancelled(msg.sender);
    }

    function setBidDealSuccess(
        address bidder,
        uint256 value
    ) public nonReentrant {
        require(
            auctionState == AuctionState.VERIFICATION,
            "Auction not VERIFICATION"
        );
        require(
            msg.sender == admin || msg.sender == bidder,
            "Txn sender not admin or SP"
        );
        require(value >= 0, "Confirm <= 0");
        Bid storage b = bids[bidder];
        require(b.bidState == BidState.SELECTED, "Deal not selected");
        require(value <= b.bidAmount - b.bidConfirmed, "Not enough value");
        if (b.bidType == BidType.BUY_NOW) {
            payable(client).transfer(value);
        } else {
            paymentToken.transfer(client, value);
        }
        b.bidConfirmed = b.bidConfirmed + value;
        if (b.bidConfirmed == b.bidAmount) {
            b.bidState = BidState.DEAL_SUCCESSFUL_PAID;
            updateAuctionEnd();
        }
        emitEvents("BidPaid");
        emit BidDealSuccessfulPaid(
            bidder,
            value,
            b.bidConfirmed == b.bidAmount
        );
    }

    //sets bid deal to fail and payout amount
    function setBidDealRefund(
        address bidder,
        uint256 refundAmount
    ) public onlyAdmin {
        require(
            auctionState == AuctionState.VERIFICATION,
            "Auction not VERIFICATION"
        );
        Bid storage b = bids[bidder];
        require(b.bidState == BidState.SELECTED, "Deal not selected");
        require(
            refundAmount <= b.bidAmount - b.bidConfirmed,
            "Refund amount > the rest"
        );
        if (b.bidType == BidType.BUY_NOW) {
            payable(bidder).transfer(refundAmount);
            payable(client).transfer(
                b.bidAmount - b.bidConfirmed - refundAmount
            );
        } else {
            paymentToken.transfer(bidder, refundAmount);
            // transfer the rest to client
            paymentToken.transfer(
                client,
                b.bidAmount - b.bidConfirmed - refundAmount
            );
        }
        b.bidState = BidState.DEAL_UNSUCCESSFUL_REFUNDED;
        updateState(AuctionState.REFUNDED);
        emitEvents("BidRefund");
        emit BidDealUnsuccessfulRefund(
            bidder,
            refundAmount,
            b.bidAmount - refundAmount
        );
    }

    // general bid
    function offerBid(address _bider, uint256 _payment) public returns (bool) {
        require(msg.sender == offerManager, "invalid caller");
        require(_bider != address(0), "invalid bidder");
        require(
            auctionState == AuctionState.BIDDING ||
                auctionState == AuctionState.SELECTION,
            "Auction not BIDDING or SELECTION"
        );
        if (!hasBidded(_bider)) {
            bidders.push(_bider);
        }
        Bid storage b = bids[_bider];
        b.bidState = BidState.SELECTED;
        b.bidAmount = _payment;
        b.bidTime = block.timestamp;
        b.bidType = BidType.OFFER;
        b.owner = _bider;
        refundUnsuccessfulBids();
        updateState(AuctionState.VERIFICATION);
        emitEvents("BidPlaced");
        emit BidPlaced(_bider, _payment, b.bidState, BidType.OFFER);
        return true;
    }

    //Helper Functions
    function getAllowance(address sender) public view returns (uint256) {
        return paymentToken.allowance(sender, address(this));
    }

    function handleBid(uint256 _bid, BidType _type) internal {
        Bid storage b = bids[msg.sender];
        if (_type == BidType.BUY_NOW) {
            require(_bid == price, "Total price not right");
            b.bidState = BidState.SELECTED;
            b.bidType = BidType.BUY_NOW;
            refundUnsuccessfulBids();
            updateState(AuctionState.VERIFICATION);
        } else {
            if (hasBidded(msg.sender)) {
                require(_bid > b.bidAmount, "Bid not higher");
                require(b.bidState == BidState.BIDDING, "Not allowed bid");
            }
            b.bidState = BidState.BIDDING;
            b.bidType = BidType.BID;
        }
        b.bidAmount = _bid;
        b.bidTime = block.timestamp;
        b.owner = msg.sender;
        emitEvents("BidPlaced");
        emit BidPlaced(msg.sender, _bid, b.bidState, _type);
    }

    function hasBidded(address bidder) private view returns (bool) {
        Bid storage b = bids[bidder];
        return b.bidTime > 0;
    }

    function updateAllOngoingBidsToPending() internal {
        for (uint8 i = 0; i < bidders.length; i++) {
            Bid storage b = bids[bidders[i]];
            if (b.bidState == BidState.BIDDING) {
                b.bidState = BidState.PENDING_SELECTION;
            }
        }
    }

    function updateAuctionEnd() internal {
        updateState(AuctionState.COMPLETED);
        emit AuctionEnded();
    }

    // only refunds bids that are currently PENDING_SELECTION.
    function refundUnsuccessfulBids() internal {
        uint8 count = 0;
        for (uint8 i = 0; i < bidders.length; i++) {
            Bid storage b = bids[bidders[i]];
            if (
                b.bidState == BidState.BIDDING ||
                b.bidState == BidState.PENDING_SELECTION
            ) {
                b.bidState = BidState.REFUNDED;
                count++;
            }
        }

        if (count > 0) {
            emit BidsUnselectedRefunded(count);
        }
    }

    function updateState(AuctionState status) internal {
        auctionState = status;
        times[status] = block.timestamp;
    }

    function emitEvents(string memory _type) internal {
        eventBus.trigger(_type);
    }

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Txn sender not admin");
        _;
    }

    modifier notExpired() {
        require(block.timestamp <= endTime, "Auction expired");
        _;
    }

    modifier onlyClientOrAdmin() {
        require(
            msg.sender == client || msg.sender == admin,
            "Txn sender not admin or client"
        );
        _;
    }

    // getters

    function getBidders() public view returns (address[] memory) {
        return bidders;
    }

    function getBids() public view returns (Bid[] memory) {
        Bid[] memory bidsArray = new Bid[](bidders.length);
        for (uint8 i = 0; i < bidders.length; i++) {
            Bid storage b = bids[bidders[i]];
            bidsArray[i] = b;
        }
        return bidsArray;
    }
}

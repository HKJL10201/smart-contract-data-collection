pragma solidity ^0.8.0;

contract Auction {
    struct AuctionItem {
        address payable highestBidder;
        uint highestBid;
        bool ended;
        uint reservePrice;
        uint biddingEndTime;
        mapping(address => uint) bids;
        mapping(address => uint) maxBids;
    }

    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    uint public totalItems;
    mapping(uint => AuctionItem) public items;

    bool public escrowActive;
    address public escrow;

    event HighestBidIncreased(uint itemId, address bidder, uint amount);
    event AuctionEnded(uint itemId, address winner, uint amount);
    event AuctionCancelled(uint itemId);

    constructor(
        uint _totalItems,
        uint _startBlock,
        uint _endBlock,
        address _escrow
    ) {
        owner = payable(msg.sender);
        totalItems = _totalItems;
        startBlock = _startBlock;
        endBlock = _endBlock;
        escrow = _escrow;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBeforeEnd(uint itemId) {
        require(block.number < items[itemId].biddingEndTime);
        _;
    }

    modifier onlyAfterEnd(uint itemId) {
        require(block.number >= items[itemId].biddingEndTime);
        _;
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    function bid(uint itemId, uint maxBid) public payable onlyBeforeEnd(itemId) {
        AuctionItem storage item = items[itemId];
        require(msg.value > item.highestBid);
        require(msg.value >= maxBid);

        if (item.highestBid != 0) {
            item.bids[item.highestBidder] += item.highestBid;
        }

        item.highestBidder = payable(msg.sender);
        item.highestBid = msg.value;

        if (maxBid > item.highestBid) {
            item.maxBids[msg.sender] = maxBid;
            item.highestBid = item.highestBid + 1;
            if (item.highestBid > maxBid) {
                item.highestBid = maxBid;
            }
        }

        emit HighestBidIncreased(itemId, item.highestBidder, item.highestBid);
    }

    function withdraw(uint itemId) public {
        AuctionItem storage item = items[itemId];
        require(item.bids[msg.sender] > 0);

        uint amount = item.bids[msg.sender];
        item.bids[msg.sender] = 0;

        if (!payable(msg.sender).send(amount)) {
            item.bids[msg.sender] = amount;
        }
    }

    function cancelAuction(uint itemId) public onlyOwner onlyBeforeEnd(itemId) {
        AuctionItem storage item = items[itemId];
        item.ended = true;
        emit AuctionCancelled(itemId);

        for (uint i = 0; i < totalItems; i++) {
            if (!items[i].ended) {
                items[i].biddingEndTime = endBlock;
            }
        }

        if (escrowActive) {
            require(payable(escrow).send(item.highestBid));
        } else {
            owner.transfer(item.highestBid);
        }
    }

    function endAuction(uint itemId) public onlyOwner onlyAfterEnd(itemId) {
        AuctionItem storage item = items[itemId];
        require(!item.ended);
        item.ended = true;

        if (item.highestBid < item.reservePrice) {
            emit AuctionCancelled(itemId);
            if (escrowActive) {
                require

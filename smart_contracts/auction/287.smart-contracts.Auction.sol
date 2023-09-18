// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
contract Auction {
    address payable public contractAddress;
    // address public highestBidder;
    // uint public highestBid;

    struct Item {
        uint itemId;
        address nftContract;
        address payable creator;
        address payable seller;
        address payable owner;
        uint tokenId;
        uint dropEndTime;
        uint auctionEndTime;
        uint price;
        address highestBidder;
        uint highestBid;
        bool auctionEnded;
        bool sold;
    }

    uint private currentItemCount;
    mapping(uint => Item) public items;
    mapping(uint => mapping(address => uint)) public bids;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /// Bid price is less than floor price.
    error BidPriceLessThanFloorPrice();
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint highestBid);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();

    /// Create a simple auction with `biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `beneficiaryAddress`.
    constructor() {
        contractAddress = payable(msg.sender);
    }

    uint public auctionEndTime;

    modifier ownerOnly() {
        require(msg.sender == contractAddress, "Not authorised to create auction.");
        _;
    }

    function createItem ( 
        address _nftContract,
        uint _tokenId,
        uint _dropDays,
        uint _auctionDays, 
        uint _price
        ) public payable{
            // require(msg.value == notableDropsCharge, "Provide the charges to utilise notable drops.");
            currentItemCount += 1;
            items[currentItemCount] = Item(currentItemCount, _nftContract, payable(msg.sender), payable(msg.sender), payable(address(0)), _tokenId, (block.timestamp + (_dropDays * 86400)), (block.timestamp + (_auctionDays * 86400)), _price, address(0), 0, false, false);
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(uint _itemId) external payable {

        if (block.timestamp > items[_itemId].auctionEndTime)
            revert AuctionAlreadyEnded();

        if (msg.value < items[_itemId].price)
            revert BidPriceLessThanFloorPrice();

        if (msg.value <= items[_itemId].highestBid)
            revert BidNotHighEnough(items[_itemId].highestBid);

        if (items[_itemId].highestBid != 0) {
            bids[_itemId][items[_itemId].highestBidder] += items[_itemId].highestBid;
        }
        
        items[_itemId].highestBidder = msg.sender;
        items[_itemId].highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function increaseBid(uint _itemId) external payable eligibleOnly(_itemId) {
        if (block.timestamp > items[_itemId].auctionEndTime)
            revert AuctionAlreadyEnded();

        if ((msg.value + bids[_itemId][msg.sender]) <= items[_itemId].highestBid)
            revert BidNotHighEnough(items[_itemId].highestBid);

        bids[_itemId][items[_itemId].highestBidder] += items[_itemId].highestBid;
        items[_itemId].highestBidder = msg.sender;
        items[_itemId].highestBid = msg.value + bids[_itemId][msg.sender];
        bids[_itemId][msg.sender] = 0;
        emit HighestBidIncreased(msg.sender, msg.value);       
    }
    
    // modifier checkBidder() {
    //     require(msg.sender != highestBidder, "You can not withdraw the highest bid.");
    //     _;
    // }

    function withdrawlEligibility(uint _itemId) public view returns (bool){
        if(msg.sender != items[_itemId].highestBidder && (bids[_itemId][msg.sender] != 0)) return true;
        else return false;
    }

    modifier eligibleOnly(uint _itemId) {
        require(msg.sender != items[_itemId].highestBidder, "The highest bid can not be withdrawn.");
        require(bids[_itemId][msg.sender] != 0, "You do not have a bid placed.");
        _;
    }

    /// Withdraw a bid that was overbid.
    function withdraw(uint _itemId) external eligibleOnly(_itemId) returns (bool) {
        uint amount = bids[_itemId][msg.sender];
        if (amount > 0) {
            bids[_itemId][msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                bids[_itemId][msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    modifier creatorOnly(uint _itemId) {
        require(msg.sender == items[_itemId].creator, "Only creator can end the auction.");
        _;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd(uint _itemId) external creatorOnly(_itemId){
        if(items[_itemId].auctionEnded)
            revert AuctionEndAlreadyCalled();

        items[_itemId].auctionEnded = true;
        emit AuctionEnded(items[_itemId].highestBidder, items[_itemId].highestBid);

        items[_itemId].creator.transfer(items[_itemId].highestBid);
    }
}
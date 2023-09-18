pragma solidity ^0.5.0;

contract AuctionList {
    uint public auctionNumber = 0;
    uint256 internal SMALLEST_TICK_IN_WEI = 500000000000000; // 0.0005 ETH approx to 0.6 USD
    uint public MAXIMUM_NUMBER_OF_DELETED_AUCTIONS = 12;

    struct Bid {
        uint256 bidPrice;
        address payable BidAddress;
    }

    struct Auction {
        uint id;
        string auctionObject;
        address payable ownerAddress;
        uint256 startPrice;
        uint256 deadline;
        address payable highestBidAddress;
        uint256 highestBid;
        bool ended;
    }

    struct DeletedAuctionsParams {
        uint size;
        uint first;
        uint last;
    }

    constructor() public {}

    mapping(uint => Auction) public auctions;
    mapping(uint => Auction) public deletedAuctionsArray;
    DeletedAuctionsParams public delAuctionsParams = DeletedAuctionsParams(0,0,0);

    event AuctionCreated(
        uint id,
        string auctionObject,
        address payable ownerAddress,
        uint256 startPrice,
        uint256 deadline,
        address payable highestBidAddress,
        uint256 highestBid,
        bool ended
    );

    event BidDone(
        uint auctionID,
        uint256 highestBid,
        address payable highestBidAddress
    );

    event AuctionEnded(
        uint auctionID,
        uint256 highestBid,
        address payable highestBidAddress
    );

    modifier auctionLive(uint auctionId) {
        require(now < auctions[auctionId].deadline, "Auction should be still live");
        _;
    }

    modifier auctionFinished(uint auctionId) {
        require(auctions[auctionId].deadline < now, "Auction should be finished");
        _;
    }

    modifier validDeadline(uint256 deadline) {
        require(now < deadline, "Deadline cannot be from the past");
        _;
    }

    modifier onlyOwner(uint auctionID) {
        require(msg.sender == auctions[auctionID].ownerAddress);
        _;
    }


    function createAuction(string memory auctionObject, uint256 startPrice, uint256 deadline) validDeadline(deadline) public {
        address payable ownerAddress = msg.sender;
        auctionNumber ++;
        auctions[auctionNumber] = Auction(auctionNumber, auctionObject, ownerAddress, startPrice, deadline, ownerAddress, 0, false);
        emit AuctionCreated(auctionNumber, auctionObject, ownerAddress, startPrice, deadline, ownerAddress, 0, false);
    }

    function getAuction(uint auctionID) public view returns (uint, string memory, address, uint256, uint256, address, uint256, bool) {
        Auction memory a = auctions[auctionID];

        return (a.id,
        a.auctionObject,
        a.ownerAddress,
        a.startPrice,
        a.deadline,
        a.highestBidAddress,
        a.highestBid,
        a.ended);
    }

    function getDeletedAuction(uint auctionID) public view returns (uint, string memory, address, uint256, uint256, address, uint256, bool) {
        Auction memory a = deletedAuctionsArray[auctionID];

        return (a.id,
        a.auctionObject,
        a.ownerAddress,
        a.startPrice,
        a.deadline,
        a.highestBidAddress,
        a.highestBid,
        a.ended);
    }

    function getDeletedAuctionsParams() public view returns (uint, uint, uint) {
        return (delAuctionsParams.first, delAuctionsParams.last, delAuctionsParams.size);
    }

    function sendWinningBidToOwner(Auction memory endedAuction) internal {
        address payable ownerAddress = endedAuction.ownerAddress;
        uint256 winningBid = endedAuction.highestBid;

        ownerAddress.transfer(winningBid);
    }

    function addAuctionToDeleted(Auction storage auction) internal {
        if (delAuctionsParams.size < MAXIMUM_NUMBER_OF_DELETED_AUCTIONS) {
            deletedAuctionsArray[delAuctionsParams.size] = auction;
            delAuctionsParams.size++;
            delAuctionsParams.last = (delAuctionsParams.last + 1) % MAXIMUM_NUMBER_OF_DELETED_AUCTIONS;
            return;
        }

        delete deletedAuctionsArray[delAuctionsParams.first];
        deletedAuctionsArray[delAuctionsParams.first] = auction;
        delAuctionsParams.last = delAuctionsParams.first;
        delAuctionsParams.first = (delAuctionsParams.first + 1) % MAXIMUM_NUMBER_OF_DELETED_AUCTIONS;
    }
}
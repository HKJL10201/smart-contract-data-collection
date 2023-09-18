// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";


contract Auction{
    event MinimumBid(uint256);

    error _onlyOwner(string);

    //**********State Variable */
    IERC721 nftAddress;
    bool started;
    bool ended;
    address seller;
    address highestBidder;
    string nftName;
    uint256 nftId;
    uint256 timeEnded;
    uint256 highestBid;
    uint256 lastcaller; // Snapshot of last bidder timestamp
    uint256 endAt;

    struct Bid {
        uint256 amount;
        uint256 timeOfBid;
    }

    mapping(address => Bid) bidder;

// The seller specify details of the NFT to be auctioned at the creation of the auction contract
    constructor(address _nftAddress, string memory _nftName, uint256 _nftId){
        nftAddress = IERC721(_nftAddress);
        require(msg.sender == nftAddress.ownerOf(_nftId), "You are not an owner of these NFT");
        seller = msg.sender;
        nftName = _nftName;
        nftId = _nftId;
    }

    modifier onlyOwner {
        if(msg.sender != seller){
            revert _onlyOwner("You are not a seller");
        }
        _;
    }

    // The seller will specify the minimum amount for the auction in wei
    function startAuction(uint256 _minBid) public onlyOwner {
        require(msg.sender == seller);
        nftAddress.transferFrom(msg.sender, address(this), nftId);
        require(!started, "The Auction already started");
        highestBid = _minBid;
        started =true;
        lastcaller = block.timestamp + 20 minutes;
        endAt = block.timestamp + 12 hours;
    }

    // We check if the bidder eth balance is greater than the minimum bid and highestbid
    function placeBid() external payable{
        if(block.timestamp >= lastcaller + 5 minutes | endAt){
            endAuction();
        }
        else{
            require(started, "Auction have not started or ended");
            require(msg.sender != address(0)); // sanity check
            require(msg.value > highestBid, "There's an higher bid");
            Bid storage bid = bidder[msg.sender];
            bid.amount += msg.value;
            bid.timeOfBid = block.timestamp;
            highestBid = bid.amount;
            highestBidder = msg.sender;
            lastcaller = bid.timeOfBid;
        }        
    }

    function endAuction() internal {
        require(!ended, "The Auction has ended");
        require(nftAddress.ownerOf(nftId) == address(this), "The NFT has been trabsferred to the highest bidder");
        require(msg.sender != address(0)); // sanity check
        nftAddress.safeTransferFrom(address(this), highestBidder, nftId);
        uint256 winnerValue = bidder[highestBidder].amount;
        bidder[highestBidder].amount = 0;
        payable(seller).transfer(winnerValue);
        ended = true;

    }
    function withdraw() public {
        require(nftAddress.ownerOf(nftId) == address(this), "The NFT has been trabsferred to the highest bidder");
        require(msg.sender != address(0)); // sanity checkt
        require(ended, "You can only withdraw after the auction ended");
        uint256 userValue = bidder[msg.sender].amount;
        bidder[msg.sender].amount = 0;
        payable(msg.sender).transfer(userValue);

    }
}
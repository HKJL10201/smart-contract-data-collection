// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/// @title Auction Contract
/// @author Kayzee

// User specify a representation of what they intend to auction
// The representation is inform of an NFT
// Bidders can see details of what they are auctioning for
// The auction payment is in eth
// The NFT is being transferrred into the contract as the auction begins
// The NFT is being transferred to the highest bidder
// The highest bidder value is being sent to the NFT owner(auction creator)
// other bidders aside the highest bidder can withdraw their auctioned amount at the end of the auction

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";


contract Auction{
    event MinimumBid(uint256);

    error _onlyOwner(string);

    //**********State Variable */
    IERC721 NFTaddress;
    bool started;
    bool ended;
    address seller;
    string NFTname;
    address highestBidder;
    uint256 NFTId;
    uint256 TimeEnded;
    uint256 highestBid;
    uint256 lastcaller; // Snapshot of last bidder timestamp
    uint256 endAt;

    struct Bid{
        uint256 amount;
        uint256 timeOfBid;
    }


    mapping(address=> Bid) bidder;

// The seller specify details of the NFT to be auctioned at the creation of the auction contract
    constructor(address _NFTaddress, string memory _NFTname, uint256 _NFTId){
        NFTaddress = IERC721(_NFTaddress);
        require(msg.sender == NFTaddress.ownerOf(_NFTId), "You are not an owner of these NFT");
        seller = msg.sender;
        NFTname = _NFTname;
        NFTId = _NFTId;
    }
// A modifier for onlyOwner
// Only the deployer of the contract can pass through the requirement

    modifier onlyOwner {
        if(msg.sender != seller){
            revert _onlyOwner("You are not a seller");
        }
        _;
    }


// The start of the auction
// The seller will specify the minimum amount for the auction in wei
    function StartAuction(uint256 _minBid) public onlyOwner {
        require(msg.sender == seller);
        NFTaddress.transferFrom(msg.sender, address(this), NFTId);
        require(!started, "The Auction already started");
        highestBid = _minBid;
        started =true;
        lastcaller = block.timestamp + 20 minutes;
        endAt = block.timestamp + 12 hours;
    }

// We check if the bidder eth balance is greater than the minimum bid and highestbid
    function PlaceBid() public payable{
        require(started, "Auction have not started or ended");
        require(msg.sender != address(0)); // sanity check
        if(block.timestamp >= lastcaller + 5 minutes | endAt){
            endAuction();
        }
        else{
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
        require(NFTaddress.ownerOf(NFTId) == address(this), "The NFT has been trabsferred to the highest bidder");
        require(msg.sender != address(0)); // sanity check
        NFTaddress.safeTransferFrom(address(this), highestBidder, NFTId);
        uint256 winnerValue = bidder[highestBidder].amount;
        bidder[highestBidder].amount = 0;
        payable(seller).transfer(winnerValue);
        ended = true;

    }
    function withdraw() public {
        require(NFTaddress.ownerOf(NFTId) == address(this), "The NFT has been trabsferred to the highest bidder");
        require(msg.sender != address(0)); // sanity checkt
        require(ended, "You can only withdraw after the auction ended");
        uint256 userValue = bidder[msg.sender].amount;
        bidder[msg.sender].amount = 0;
        payable(msg.sender).transfer(userValue);

    }
}

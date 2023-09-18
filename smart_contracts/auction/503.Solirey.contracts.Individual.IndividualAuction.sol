// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract IndividualAuction is IERC721Receiver {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address payable public beneficiary;
    uint public auctionEndTime;
    uint256 public tokenId;
    ERC721 nftContract;
    uint public startingBid;
    bool tokenAdded;
    bool isWithdrawn;
    address payable admin;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) public pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        uint _startingBid,
        address payable _admin
    ) payable {
        beneficiary = payable(msg.sender);
        auctionEndTime = block.timestamp + _biddingTime;
        startingBid = _startingBid;
        admin = _admin;
    }
    
    function abort() external {
        require(
            beneficiary == msg.sender,
            "Not authorized"
        );
        
        require(
            highestBidder == address(0),
            "Already bid"
        );
        
        require(
            block.timestamp <= auctionEndTime,
            "Auction already expired"
        );
        
        require(
            ended == false,
            "Auction already ended"
        );
        
        ended = true;
        
        nftContract.transferFrom(address(this), beneficiary, tokenId);
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() external payable {
        require(
            tokenAdded == true,
            "Token must be added first."
        );

        require(
            block.timestamp <= auctionEndTime,
            "Auction already ended."
        );

        require(
            msg.value > highestBid,
            "Higher bid already exists."
        );
        
        require(
            msg.value > startingBid,
            "Too low"
        );
        
        require(
            msg.sender != beneficiary,
            "Can't bid on your own auction"
        );

        pendingReturns[highestBidder] += highestBid;
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        require(highestBidder != msg.sender, "Unauthorized");

        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {
        require(block.timestamp >= auctionEndTime, "Auction has not yet ended.");
        require(ended == false, "Auction has already been ended.");

        ended = true;
        
        if (highestBidder == address(0)) {
            highestBidder = beneficiary;
        }
        
        nftContract.safeTransferFrom(address(this), highestBidder, tokenId);
        
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    function getTheHighestBid() external {
        require(msg.sender == beneficiary, "You are not the beneficiary");
        require(block.timestamp >= auctionEndTime, "Active auction");
        require(ended == true, "Auction has not yet ended.");
        require(isWithdrawn == false, "Already withdrawn"); 
        
        isWithdrawn = true;

        uint af = highestBid * 2 / 100;
        uint payout = highestBid - af;
        
        admin.transfer(af);
        beneficiary.transfer(payout);
    }
    
    // function transferToken() public {
    //     require(block.timestamp >= auctionEndTime, "Bidding time has not expired.");
    //     require(ended, "Auction has not yet ended.");
        
    //     if (highestBidder == address(0)) {
    //         highestBidder = beneficiary;
    //     }
        
    //     require(msg.sender == highestBidder, "You are not the highest bidder");

    //     nftContract.safeTransferFrom(address(this), highestBidder, tokenId);
    // }
    
    function onERC721Received(address, address, uint256 _tokenId, bytes memory) public virtual override returns (bytes4) {
        require(beneficiary == tx.origin, "Unauthorized");
        require(tokenAdded == false, "The auction already has a token.");
        
        nftContract = ERC721(msg.sender);
        tokenId = _tokenId;
        tokenAdded = true;
        return this.onERC721Received.selector;
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SealedBidAuction {
    // @title A simple smart contract for auction bidding.
    // @author Anshik Bansal

    // Auction parameters
    address public immutable beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    
    uint public highestBid;
    address public highestBidder;
    bool public hasEnded;

    // Amount withdrawable of previous bids
    mapping(address => uint) pendingReturns;

    struct Bid {
        bytes32 sealedBid;
        uint deposit;
    }

    mapping(address => Bid[]) public bids;


    // Events
    event NewBid(address indexed bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Modifiers to check function be called only if the written criteria's are met
    modifier onlyBefore(uint time) {
        require(block.timestamp < time, "Too Late");
        _;
    }

    modifier onlyAfter(uint time) {
        require(block.timestamp > time, "Too Early");
        _;
    }


    constructor (address _beneficiary, uint _durationBiddingMinutes, uint _durationRevealMinutes) {
        beneficiary = _beneficiary;
        biddingEnd = block.timestamp + _durationBiddingMinutes * 1 minutes;
        revealEnd = block.timestamp + _durationRevealMinutes * 1 minutes;
    }

    // Keeping a track record of the bids a user has made
    function bid(bytes32 _sealedBid) external payable onlyBefore(biddingEnd) {
        Bid memory newBid = Bid({
            sealedBid : _sealedBid,
            deposit : msg.value
        });
        bids[msg.sender].push(newBid);
    }

    // Update the bid, if the bidder puts higher bid amount
    function updateBid(address _bidder, uint _bidAmount) internal returns (bool success) {
        if (_bidAmount <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = _bidAmount;
        highestBidder = _bidder;
        return true;
    }

    function reveal(uint[] calldata _bidAmounts, bool[] calldata _areLegits, string[] calldata _secrets) 
    external 
    onlyAfter(biddingEnd)
    onlyBefore(revealEnd) 
    {
        uint nbids = bids[msg.sender].length;
        require(_bidAmounts.length == nbids, "Invalid number of bids amount");
        require(_areLegits.length == nbids, "Invalid number of bids legitmacy indicators");
        require(_secrets.length == nbids, "Invalid numbers of bids secrets");
        uint totalRefund;

        for(uint i = 0; i < nbids; i++){
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint bidAmount, bool isLegit, string memory secret) = (_bidAmounts[i], _areLegits[i], _secrets[i]);
            bytes32 hashedInput = generateSealedBit(bidAmount, isLegit, secret);
            if (bidToCheck.sealedBid != hashedInput){
                continue;
            }
            totalRefund += bidToCheck.deposit;
            if (isLegit && bidToCheck.deposit >= bidAmount) {
                bool success = updateBid(msg.sender, bidAmount);
                if (success){
                    totalRefund -= bidAmount;
                }
            }
            bidToCheck.sealedBid = bytes32(0);
        }
        
    if (totalRefund > 0){
        payable(msg.sender).transfer(totalRefund);
    }
}

    // Function to let user withdraw their pending amount
    function withdraw() external returns (uint amount) {

        amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    // Ending the auction after the revealing of the bid has been made public
    function auctionEnd() external onlyAfter(revealEnd) {
        require(!hasEnded, 'Auction already Ended');
        emit AuctionEnded(highestBidder, highestBid);
        hasEnded = true;
        payable(beneficiary).transfer(highestBid);
    }

    // Generate sealed bid so as other users are not aware of the bid amount, till the bidding end
    function generateSealedBit(uint _bidAmount, bool _isLegit, string memory _secret) public pure returns (bytes32 sealedBid) {
        sealedBid = keccak256(abi.encodePacked(
            _bidAmount, _isLegit, _secret));
    }
}
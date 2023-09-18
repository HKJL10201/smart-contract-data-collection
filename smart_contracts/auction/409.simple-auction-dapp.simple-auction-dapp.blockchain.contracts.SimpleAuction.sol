// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.7.0;

contract SimpleAuction {
    uint biddingTime;  // Constant variable, how long each auction will run. 
    address payable public beneficiary;
    uint public auctionStartTime;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;

    bool public ended;

    address payable[] public bidders;  // Tracks the bidders for the current auction
    mapping(address => uint) public treasuryBalances;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event TreasuryBalanceReturned(address claimee, uint amount);
    
    constructor(uint _biddingTime) public {
        beneficiary = payable(msg.sender);
        auctionStartTime = now;
        auctionEndTime = now + _biddingTime;
        biddingTime = _biddingTime;
    }

    function _reset() public {
        // Used to reset the auction (CANNOT BE RESET UNTIL PREVIOUS AUCTION IS ENDED)
        require(msg.sender == beneficiary, "Only the beneficiary can reset the auction.");
        require(ended, "Auction cannot be reset until previous auction has ended.");

        // Bidders array should be cleared since it's a new auction, but teasuryBalances mapping should not be.
        bidders = new address payable[](0);
        
        // Restart the auction
        ended = false;
        auctionStartTime = now;
        auctionEndTime = now + biddingTime;
        highestBid = 0;
        highestBidder = address(this);
    }

    function treasury() public view returns (uint) {
        // Returns the amount of money current in the contract's treasury
        return address(this).balance;
    }

    function bid() public payable {
        require(now <= auctionEndTime, "The auction has ended!");
        require(msg.value > treasuryBalances[highestBidder], "There is a higher bid!");
        require(msg.value > 0, "The bid should be greater than 0.");

        uint previousBalance = treasuryBalances[msg.sender];

        treasuryBalances[msg.sender] += msg.value;
        highestBidder = msg.sender;
        highestBid = msg.value;

        // Unique bidder, push to bidders list
        if (previousBalance == 0) {
            bidders.push(payable(msg.sender));
        }

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function getBidders() public view returns (address payable[] memory) {
        return bidders;
    }

    function claimBalance() public returns (uint) {
        // Returns any available claims balance in the treasury on behalf of the sender, and returns the amount claimed (returned) to the sender
        // Can only be called after the auction is over
        require(now >= auctionEndTime, "Auction has not yet ended.");
        require(ended, "Auction has ended, but funds cannot be claimed until auctionEnd is called to settle the auction.");
        
        uint amount = treasuryBalances[msg.sender];
        require(amount > 0, "You have no funds to claim.");

        treasuryBalances[msg.sender] = 0;
        msg.sender.transfer(amount);

        emit TreasuryBalanceReturned(msg.sender, amount);

        return amount;
    }

    function auctionEnd() public {
        // Should be called after the auction has ended to finalize the auction
        require(now >= auctionEndTime, "Auction cannot be ended yet.");
        require(! ended, "Method has already been called; The auction has ended.");

        ended = true;

        // Transfer the highest bid to the beneficiary
        beneficiary.transfer(highestBid);
        treasuryBalances[highestBidder] -= highestBid;

        emit AuctionEnded(highestBidder, highestBid);
    }
}
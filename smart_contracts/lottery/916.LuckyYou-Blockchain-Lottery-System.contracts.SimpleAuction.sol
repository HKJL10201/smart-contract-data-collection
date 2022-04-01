pragma solidity >=0.4.22 <0.7.0;

contract SimpleAuction {

    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor (uint _biddingTime, address payable _benificiary) public {
        beneficiary = _benificiary;
        auctionEndTime = now + _biddingTime;
    }

    // the value will be refuned if the auction is not won
    function bid() public payable {
        
        require(
            now <= auctionEndTime,
            "Auction already edned."
        );

        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // end the auction and send the highest bid to the beneficiary.
    function auctionEnd() public {
        // Sending Ether is another contract. should be done in following stages:
        // 1. chacking conditions
        // 2. performaing actions
        // 3. interacting with other contracts

        // 1.Conditions
        require(now >= auctionEndTime, "Auction not yet ended.");        
        require(!ended, "auctionEnd has already been called.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}

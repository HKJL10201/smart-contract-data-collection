pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;

    // Current state of the auction. You can create more variables if needed
    address public highestBidder;
    uint public highestBid;
    unit public temp;
    bool public status = true;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Constructor
    constructor() public {
        beneficiary = msg.sender;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable {

        require(msg.value > highestBid && status);
        // TODO If the bid is not higher than highestBid, send the
        // money back. Use "require"

        pendingReturns[highestBidder] += highestBid;
        highestBidder = msg.sender;
        highestBid = msg.value;

        // TODO update state

        // TODO store the previously highest bid in pendingReturns. That bidder
        // will need to trigger withdraw() to get the money back.
        // For example, A bids 5 ETH. Then, B bids 6 ETH and becomes the highest bidder.
        // Store A and 5 ETH in pendingReturns.
        // A will need to trigger withdraw() later to get that 5 ETH back.

        // Sending back the money by simply using
        // highestBidder.send(highestBid) is a security risk
        // because it could execute an untrusted contract.
        // It is always safer to let the recipients
        // withdraw their money themselves.

    }

//----------------------------------------------------------------------------------------------------------------------------------------------------------------

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
/*
Check for all the addresses in the map and return true if value exists
*/
        // TODO send back the amount in pendingReturns to the sender. Try to avoid the reentrancy attack. Return false if there is an error when sending
        if (pendingReturns[msg.sender] > 0) {
          temp = pendingReturn[msg.sender];
          pendingReturn[msg.sender] = 0;
          msg.sender.transfer(temp);
          return true;
        } else {
          return false;
        }

    }
//----------------------------------------------------------------------------------------------------------------------------------------------------------------

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // TODO make sure that only the beneficiary can trigger this function. Use "require"
        require(msg.sender == beneficiary && status);
        status = false;
        msg.sender.transfer(highestBid);
        // TODO send money to the beneficiary account. Make sure that it can't call this auctionEnd() multiple times to drain money

    }
}

/* Commands for Execution

let val = await Auction.deployed()
let accounts = await web3.eth.getAccounts()
val.bid({from:accounts[3], value:3000000000000000000})

*/

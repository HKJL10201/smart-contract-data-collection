pragma solidity ^0.5.0;

contract Auction {
    address payable public beneficiary;

    // Current state of the auction. 
    address public highestBidder;
    uint public highestBid;


    //flag for action to be called once to know if auction has ended once
    bool called_auction=false;
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

        //Only bids higher than the highest bids are placed
        require(msg.value>highestBid,"Lower Balance");
        //Just a casual prev state check
        //We know that msg.value is greater than the highestbid's state
        if(highestBid>0)
        {
            //return the previous highest bid to the previous highest bidder
            pendingReturns[highestBidder]+=highestBid;
        }
        //Update the highest bid and the bidder
        highestBid=msg.value;
        highestBidder=msg.sender;

        // Sending back the money by simply using
        // highestBidder.send(highestBid) is a security risk
        // because it could execute an untrusted contract.
        // It is always safer to let the recipients
        // withdraw their money themselves.
        
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
            uint amount=pendingReturns[msg.sender];
            if(amount>0)
            { //Preventing reentrancy just by setting the amount to 0 till withdrawal is complete.
                pendingReturns[msg.sender]=0;
                if(!msg.sender.send(amount))
                {
                    pendingReturns[msg.sender]=amount;
                    return false;
                }

            }
            return true;

    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        
        // Adding a flag to avoid repeated endAuction Calls
        require(called_auction==false);
        // making sure that only the beneficiary can trigger this function. Use "require"
        require(msg.sender== beneficiary,"You are not the beneficiary");
        
        called_auction=true;
        beneficiary.transfer(highestBid);
        
    }
}
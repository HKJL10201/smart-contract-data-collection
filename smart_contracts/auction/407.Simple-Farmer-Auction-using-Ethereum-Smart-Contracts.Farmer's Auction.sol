pragma solidity >=0.4.22 <0.6.0;

contract Auction {

    address payable public farmer;
    uint public auctionEndTime;
    
    
    address public highestBidder;
    uint public highestBid;
    uint MSP;
    string productname;
    
    // mapping(address => uint) pendingReturns;
    bool ended;

   
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    constructor(
        uint _biddingTime,
        address payable _beneficiary,
        uint _MSP,
        string memory _productname
    ) public {
        farmer = _beneficiary;
        auctionEndTime = now + _biddingTime;
        highestBid=_MSP;
        productname=_productname;
    }

    function bid(uint k) public {
 
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );

  
        require(
            k > highestBid,
            "There already is a higher bid."
        );

        highestBidder = msg.sender;
        highestBid = k;
        emit HighestBidIncreased(msg.sender, highestBid);
    }

    /// Withdraw a bid that was overbid.
    // function withdraw() public returns (bool) {
    //     uint amount = pendingReturns[msg.sender];
    //     if (amount > 0) {    
    //         pendingReturns[msg.sender] = 0;
    //         if (!msg.sender.send(amount)) {
    //             pendingReturns[msg.sender] = amount;
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    function auctionSTATUS() public {
      
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "Auction has already ended.");

      
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // beneficiary.transfer(highestBid);
    }
}

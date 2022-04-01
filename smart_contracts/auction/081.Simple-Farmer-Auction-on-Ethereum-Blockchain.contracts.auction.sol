pragma solidity >=0.4.22 <0.9.0;

//pragma solidity >=0.4.22 <0.6.0;

contract Auction {

    address payable public farmer;
    uint public auctionEndTime;
    address public highest_bidder;
    uint public highest_bid;
    uint MSP;
    string productname;    
    bool ended;

   
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    constructor(
        uint _biddingTime,
        //address payable _beneficiary,
        uint _MSP,
        string memory _productname
    ) public {
        farmer = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
        MSP = _MSP;
        productname = _productname;
    }


    function bid(uint k) public {
        require(
            block.timestamp <= auctionEndTime,
            "Auction already ended."
        );
        require(
            k > highest_bid,
            "There already is a higher bid."
        );

        highest_bidder = msg.sender;
        highest_bid = k;
        emit HighestBidIncreased(msg.sender, highest_bid);
        //return highest_bid;
    }

    function getFarmer() public view returns(address){
        return farmer;
    }

    function getAuctionEndTime() public view returns(uint256){
        return auctionEndTime;
    }

    function getHighestBid() public view returns(uint){
        return highest_bid;
    }

    function getHighestBidder() public view returns(address){
        return highest_bidder;
    }

    function getMSP() public view returns(uint){
        return MSP;
    }


    function auctionSTATUS() public {
      
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "Auction has already ended.");
        ended = true;
        emit AuctionEnded(highest_bidder, highest_bid);
        // farmer.transfer(highest_bid);
    }
}
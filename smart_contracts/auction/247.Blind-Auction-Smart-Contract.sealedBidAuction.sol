// SPDX-License-Identifier: MIT

/*
 * @title Sealed Bid Auction
 * @author Brodie Gould
 * @dev for a large N number of bidders, the smart contract size limit could be exceeded
 */

/// @notice compiler version specified
pragma solidity 0.8.4;

contract SealedEnvelopeAuction{

    // VARIABLES
    address payable public seller;                        
	address public highestBidder;
	uint    public highestBid;

    uint public endBiddingTime;                             
    uint public endRevealingTime;                           
    bool public ended = false;

    uint private bidCount = 0;
    uint private revealedCount = 0;

    mapping (address => uint)  public pendingReturns;

    struct Bid {
        bytes32 sealedBid;
        uint depositAmt;
    }

    mapping (address => Bid[]) public bidMap;
    
    // EVENTS 
    event AuctionEnded(address winner, uint highestBid);

    // MODIFIERS
    modifier onlyBefore(uint _time) { require(block.timestamp < _time, "Too Late"); _; }
    modifier onlyAfter(uint _time) { require(block.timestamp > _time, "Too Early"); _; }
    
    // CONSTRUCTOR
    constructor(uint _biddingTime, uint _revealTime) {
        seller = payable(msg.sender);                                     
        endBiddingTime = block.timestamp + (_biddingTime * 1 minutes);            
        endRevealingTime = endBiddingTime + (_revealTime * 1 minutes); 
    }
    // FUNCTIONS
    function sealBid(uint _value, string calldata _passcode) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_value,  _passcode, msg.sender));
    }

    function bid(bytes32 _sealedBid) external payable onlyBefore(endBiddingTime) {
        require(msg.sender != seller,"The host of the auction can't bid on their own auction");
        require(msg.value > 0,"You can't bid nothing");
        require(bidMap[msg.sender].length < 1,"There can only be one bid per account");

        bidMap[msg.sender].push(Bid({                               
            sealedBid: _sealedBid,                   
            depositAmt: msg.value                   
        }));

        bidCount +=1;
    }

    function reveal(uint _value, string memory _passcode) external onlyAfter(endBiddingTime) onlyBefore(endRevealingTime) {
        Bid storage myBid = bidMap[msg.sender][0];  
        uint value = _value;
        string memory passcode = _passcode;
        require(myBid.sealedBid == keccak256(abi.encodePacked(value, passcode, msg.sender)),"The sealedBid doesn't match the hash");
        /// @notice .encode -> .encodePacked

        if(myBid.depositAmt == value){             //if this is a valid bid
			myBid.sealedBid = bytes32(0);
			if(!checkBid(msg.sender, value)) { 
                payable(msg.sender).transfer(myBid.depositAmt); 
                /// @notice bidToCheck -> myBid
            }
        }
      
    revealedCount +=1; 
    } 

    function checkBid(address _bidder, uint _value) internal returns(bool success) {      
        uint value = _value;
        address bidder = _bidder;
        if (value < highestBid){
            pendingReturns[payable(msg.sender)] = value;
            return false;       //not a higher bid
        }

        if (highestBidder != address(0)) {                  
            pendingReturns[highestBidder] += highestBid;    
        }
        highestBid = value;                                 
        highestBidder = bidder;
        return true;                   //a higher bid
    }
    
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];        
        if(amount > 0){                                 
            pendingReturns[msg.sender] = 0;                     
            payable(msg.sender).transfer(amount);  
        }
    }
    function endAuction() public payable onlyAfter(endRevealingTime) {
        require(!ended, "Auction has already ended");    
        require(bidCount == revealedCount, "Not every bid has been revealed yet");  

        emit AuctionEnded(highestBidder, highestBid);
        ended = true;                       
        seller.transfer(highestBid);  
    }
}

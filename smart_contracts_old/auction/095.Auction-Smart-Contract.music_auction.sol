
pragma solidity >=0.7.0 <0.8.0;

contract MusicAuction{
    
    address payable public auctionManager;
    uint public auctionManagerDeposit;
    uint public minimumDeposit;
    uint public startTime;
    uint public biddingTime;
    uint public revealingTime;
    bool public auctionFinalizedByManager = false;
 
    

    
    struct Bidder {
        bytes32 commitment; 
        uint value; 
        uint nonce;  
        bool seen;
        uint deposit;
        bool cheater;
        bool reclaimedDeposit;
        
    }
    
    address payable[] public bidderAddresses;
    address payable public highestPriceAddress;
    uint public highestPrice = 0;
    uint public secondHighestPrice = 0;
    
    mapping(address => Bidder) public bidders;
    
    constructor(uint _biddingTime, uint _revealingTime, uint256 _minimumDeposit ) payable{
        auctionManager = msg.sender;
        startTime = block.timestamp;
        auctionManagerDeposit = msg.value;
        biddingTime = _biddingTime;
        revealingTime = _revealingTime;
        minimumDeposit = _minimumDeposit;
        require( auctionManagerDeposit >= minimumDeposit, "Your deposit should be greater than or equal the minimum deposit value");
    }
     
     
      function sendBid(bytes32 commitment ) public payable {
        
         require(block.timestamp  <= (startTime + (biddingTime * 1 days )), "Bidding Period is over");
         require(!bidders[msg.sender].seen, "You have already sent a bid.");
         require(msg.value  >= minimumDeposit , "Your deposit value is less than the required minimum value.");
         bidders[msg.sender].deposit = msg.value;
         bidders[msg.sender].seen = true;
         bidders[msg.sender].commitment = commitment;
         bidders[msg.sender].cheater = true;
         bidders[msg.sender].reclaimedDeposit = false;
         bidderAddresses.push( msg.sender);
     }
     
   
       function createCommitment(address publicKey, uint value, uint nonce) public pure returns (bytes32) {
        return keccak256( (abi.encode( publicKey, value, nonce) ));
    }
     
     function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
     function sendValues(uint value, uint nonce ) public payable {
        
         require(block.timestamp > startTime  + (biddingTime * 1 days ), "Revealing time has not started yet");
         require(block.timestamp  <= startTime + (biddingTime * 1 days) + (revealingTime * 1 days) , "Revealing time is over");
         bytes32 newComit = createCommitment(msg.sender, value, nonce );
         require(newComit ==  bidders[msg.sender].commitment, "Revealed values do not match previous commitment.");
         require( (msg.value + bidders[msg.sender].deposit)  >= value , "Sent value and deposit is smaller than the proposed value in commitment.");
         bidders[msg.sender].cheater = false;
         bidders[msg.sender].nonce = nonce;
         bidders[msg.sender].value = msg.value + bidders[msg.sender].deposit;
         if( value > highestPrice )
         {  
            secondHighestPrice = highestPrice;
            highestPrice = value;
            highestPriceAddress = msg.sender;
         } else if ( value > secondHighestPrice )
         {
             secondHighestPrice = value;
         }
         
     }
     
    
     
     function finalizeByManager() public {
         
         require( msg.sender == auctionManager, "Only Auction Manager can call this function");
         require( auctionFinalizedByManager == false, "The auction has already been finalized by the manager.");
         require(block.timestamp > startTime + (biddingTime * 1 days) + (revealingTime * 1 days) , "Finalization time has not started yet.");
         
         auctionManager.transfer( auctionManagerDeposit);
         
         for (uint i = 0; i < bidderAddresses.length; i ++) 
            if( bidders[bidderAddresses[i]].cheater == true)
                auctionManager.transfer(bidders[bidderAddresses[i]].deposit);
           
        uint256 finalPrice;     
        if( secondHighestPrice > 0 )
            finalPrice = secondHighestPrice;
        else
            finalPrice = highestPrice;
            
        if( highestPriceAddress != address(0)){
            uint payBackToWinner = bidders[highestPriceAddress].value - finalPrice;
            highestPriceAddress.transfer( payBackToWinner);
            auctionManager.transfer( finalPrice);
        }    
        
        auctionFinalizedByManager = true;
        
    }
     
    function finalizeByBidder() public{
        
         require( block.timestamp  > startTime + (biddingTime * 1 days ) + (revealingTime * 1 days ) , "Revealing Period is not over yet!");
         require( highestPriceAddress != msg.sender, "You won the auction! Your payment will be sent to the Auction Manager.");
         require( bidders[msg.sender].seen == true, "You have not participated in this auction.");
         require( bidders[msg.sender].cheater == false, "You have not revealed your values correctly, you will not be able to receive your deposit");
         require(bidders[msg.sender].reclaimedDeposit == false, "You have already reclaimed your deposit.");
         bidders[msg.sender].reclaimedDeposit = true;
         msg.sender.transfer( bidders[msg.sender].value );
        
     }
     
     
}

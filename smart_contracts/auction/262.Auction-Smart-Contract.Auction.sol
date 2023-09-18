pragma solidity >=0.4.22 <0.7.0;

contract Auction{

    struct Bid {
        bytes32 hiddenBid;
        uint deposit;
        uint valueToBeRefunded;
        bool bidded ;
        bool honest ;
    }
    
    address payable public manager;
    
    uint public managerDeposit;
    address public highestBidder;
    uint public highestBid;
    uint public secondHighestBid;
    
    uint public biddingCloses;
    uint public revealCloses;
    uint public finalizeCloses;
    bool public ended;
    uint public cheaterDeposits=0;
    
    address  payable[] public refunds  ;

    mapping(address => Bid) public bids;

    constructor(uint bidDuration, uint revealDuration, uint finalizeDuration) public payable {
        require(msg.value >= 0.001 ether ,
        " Deposit must be >= 0.001 ether");
        ended = false;
        highestBid = 0;
        secondHighestBid = 0;
        biddingCloses = block.timestamp + bidDuration *1 days ;
        revealCloses = biddingCloses + revealDuration  *1 days;
        finalizeCloses = revealCloses + finalizeDuration *1 days;
        manager = msg.sender;
        managerDeposit = msg.value;
    }
    
    function createCommitment(address bidder, uint rand, uint value) public pure returns (bytes32) {
        return keccak256(abi.encode(bidder, value, rand));
    }
    
    
    function bid(bytes32 hash) public payable
    {
        require(
            block.timestamp <= biddingCloses,
            "Bidding time ended"
        );
        
        require(
            msg.sender != manager,
            "Manager can't make a bid"
        );
        
        require(msg.value >= 0.001 ether ,
        " Deposit must be >= 0.001 ether");

        //assume that the bidder can only bid once
        require(bids[msg.sender].bidded==false, "You can only bid once");
        
        cheaterDeposits = cheaterDeposits + msg.value;
        bids[msg.sender] = Bid({
            hiddenBid: hash,
            deposit: msg.value,
            valueToBeRefunded:0,
            bidded: true,
            honest: false
        });

    }
    
    
    function reveal(uint rand, uint value) public payable {
        require(block.timestamp > biddingCloses , "Bidding time didn't close");
        require(block.timestamp <= revealCloses , "Revealing time closed");
        bytes32 hash = createCommitment(msg.sender, rand,value);
        
        require(hash == bids[msg.sender].hiddenBid,
        "You Cheated, you can't get your money back");
        
        require(msg.value== value - bids[msg.sender].deposit , "You must pay the same value you commited");
        
        if(value > highestBid)
          {
            highestBidder = msg.sender;
            secondHighestBid = highestBid;
            highestBid = value;
          }
        else if( value> secondHighestBid)
          {
              secondHighestBid = value;
          }
          
        cheaterDeposits = cheaterDeposits - bids[msg.sender].deposit;
        bids[msg.sender].valueToBeRefunded = value ;
        bids[msg.sender].honest = true;
        refunds.push(msg.sender);
        }
         
         
    function finalizeAuction() public {
        require(block.timestamp > revealCloses , "Revealing time didn't close");  
        require(block.timestamp <= finalizeCloses , "Finalize time closed");
        require(msg.sender == manager , "Only the manager can call this function");
        require(ended == false , "The auction already ended");
        
        ended = true;
        
        for (uint i=0; i<refunds.length; i++) {
            if(highestBidder == refunds[i])
            {
               refunds[i].transfer(highestBid-secondHighestBid);
            }
            else{
               refunds[i].transfer(bids[refunds[i]].valueToBeRefunded);
            }
       }
       
        msg.sender.transfer(managerDeposit+secondHighestBid+cheaterDeposits);

    }
    
    
    function participantFinalize() public {
        require(ended == false , "The auction already ended");
        require(block.timestamp > finalizeCloses , "The manager can still finalize the auction");
        require(msg.sender!=manager);
        require(bids[msg.sender].honest==true , " You must be an honest participant");
        
        ended = true;
        uint cheaterDepositRatio = cheaterDeposits/refunds.length;
        for (uint i=0; i<refunds.length; i++) {
               refunds[i].transfer(bids[refunds[i]].valueToBeRefunded + cheaterDepositRatio);
       }
        msg.sender.transfer(managerDeposit/2);
        manager.transfer(managerDeposit/2);
    }
    
}
    
   

    
    

    
    
    

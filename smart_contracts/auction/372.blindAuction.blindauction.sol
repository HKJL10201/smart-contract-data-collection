pragma solidity >=0.5.0 <0.6.0;

contract BlindAuction{

    
    event OwnerSet(address oldOwner, address newOwner);
    event WinnerSet (address winner, uint value);

    // the auctionManager is the seller
    address public auctionManager;
    uint deposit = 500 wei;
    // the owner is initially the auctionManager
    address public owner;
    bool isAuctionEnded = false;

     
    mapping(address => bytes32) public biddings;
    mapping(address => uint) public validBiddings;
    mapping(address => bool) public refunds;


    uint highestBid;
    uint secondHighestBid;
    address highestBidder;
    uint biddingTime;
    uint revealingTime;
    uint private song;
    
    modifier duringBidding() {
    require(now <= biddingTime, 'It is not Bidding Time');
    _;
  }
  
   modifier duringRevealing() {
    require(now > biddingTime && now <= revealingTime, 'It is not Revealing Time');
    _;
  }
  
   modifier afterRevealing() {
    require(now > revealingTime, 'Auction has not been ended yet');
    _;
  }
    constructor(uint _biddingTime, uint _revealingTime, uint _song) public{
        auctionManager = msg.sender; 
        // auctionManager is the owner, no middlemen
        owner = msg.sender; 
        biddingTime = now + _biddingTime;
        revealingTime = biddingTime + _revealingTime;
        song = _song;
        
    }

    function sealBid(uint _value, uint _nonce) private  returns (bytes32){
        return keccak256(abi.encode(_value, _nonce, msg.sender));
    }
    
    
    function bid(bytes32 sealedBid, uint _nonce) public payable duringBidding{
        // Participant pays bid once
        require(refunds[msg.sender] == false, 'Already participated' );
        require(msg.value == deposit,'Please make sure you pay the deposit');
        require(msg.sender != auctionManager, 'Auction Manager has no rights to bid');
        //bytes32 sealedBid = sealBid(_value, _nonce);
        biddings[msg.sender] = sealedBid;
        refunds[msg.sender] = true;
    
    }
    
    function reveal(uint _value, uint _nonce) public duringRevealing{
        // checks for the validity of bids
        // on reveal, each pariticapant will not pay, just reveal the values
        require(msg.sender != auctionManager);
        if (biddings[msg.sender] == sealBid(_value, _nonce)){
            if (_value > highestBid){
            secondHighestBid = highestBid;
            highestBid = _value;
            highestBidder = msg.sender;
        }
        
        validBiddings[msg.sender] = _value;

        }

    }
    
    function finalizeAuction() public afterRevealing{
        // auction ends just one time
        require(isAuctionEnded == false);
        isAuctionEnded = true;
        // delete the winner from the map he won't get the deposit back
        delete validBiddings[highestBidder];
        emit WinnerSet(highestBidder, secondHighestBid);
        
    }
   
   function withdraw() public afterRevealing{
       // check if he is not a cheater nor a winner
       require(validBiddings[msg.sender]!= uint(0x0));
       require(msg.sender != auctionManager);
       //check if already refunded
       require(!refunds[msg.sender]);
       msg.sender.transfer(deposit);
       refunds[msg.sender] = true;
   }
   
   function claim() public payable afterRevealing returns (uint){
       //set the winner as the song owner
       // winner has the write to transfer ownership to himself
       require(msg.value == secondHighestBid);
       require(msg.sender == highestBidder);
       owner = highestBidder;
       emit OwnerSet(auctionManager, highestBidder);
       return song;
             
   }
   

}
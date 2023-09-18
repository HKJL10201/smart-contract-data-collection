pragma solidity >=0.5.0 <0.9.0;
 
 
contract Auction{
    address payable public owner;   // defining the owner
    uint public startBlock;         // variable  
    uint public endBlock;           // variable
    string public ipfsHash;         // variable
 
    
    enum State {Started, Running, Ended, Canceled}  // Stati der Auktion -> Hauptsächlich zur Übersicht 
    State public auctionState;
    
    uint public highestBindingBid;                      // Höchstbietender 
    
    
    address payable public highestBidder;               // Höchstbietender Adresse
    mapping(address => uint) public bids;               // alle Bieter -> Synatx gleich wie bei Array
    uint bidIncrement;                                  // Zuwachs der Gebote
        
 
    constructor(){
        owner = payable(msg.sender);                    // Owner ist Contract Ersteller
        auctionState = State.Running;                   
        
        startBlock = block.number;                      
        endBlock = startBlock + 3;
      
        ipfsHash = "";
        bidIncrement = 1000000000000000000; // bidding in multiple of ETH
    }
    
    // declaring function modifiers
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    
    
    //a helper pure function (it neither reads, nor it writes to the blockchain)
    function min(uint a, uint b) pure internal returns(uint){
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    // only the owner can cancel the Auction
    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }
    
    
    // the main function called to place a bid
    function placeBid() public payable notOwner afterStart beforeEnd returns(bool){
        // to place a bid auction should be running
        require(auctionState == State.Running);
        // minimum value allowed to be sent
        // require(msg.value > 0.0001 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        
        // the currentBid should be greater than the highestBindingBid. 
        // Otherwise there's nothing to do.
        require(currentBid > highestBindingBid);
        
        // updating the mapping variable
        bids[msg.sender] = currentBid;
        
        if (currentBid <= bids[highestBidder]){ // highestBidder remains unchanged
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{ // highestBidder is another bidder
             highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
             highestBidder = payable(msg.sender);
        }
    return true;
    }
    
    
    
    function finalizeAuction() public{
       // the auction has been Canceled or Ended
       require(auctionState == State.Canceled || block.number > endBlock); 
       
       // only the owner or a bidder can cancel the auction
       require(msg.sender == owner || bids[msg.sender] > 0);
       
       // the recipient will get the value
       address payable recipient;
       uint value;
       
       if(auctionState == State.Canceled){ // auction canceled, not ended
           recipient = payable(msg.sender);
           value = bids[msg.sender];
       }else{// auction ended, not canceled
           if(msg.sender == owner){ //the owner finalizes the auction
               recipient = owner;
               value = highestBindingBid;
           }else{// another user (not the owner) finalizes the auction
               if (msg.sender == highestBidder){
                   recipient = highestBidder;
                   value = bids[highestBidder] - highestBindingBid;
               }else{ //this is neither the owner nor the highest bidder (it's a regular bidder)
                   recipient = payable(msg.sender);
                   value = bids[msg.sender];
               }
           }
       }
       
       // resetting the bids of the recipient to avoid multiple transfers to the same recipient
       bids[recipient] = 0;
 
       //sends value to the recipient
       recipient.transfer(value);
     
    }
 
}

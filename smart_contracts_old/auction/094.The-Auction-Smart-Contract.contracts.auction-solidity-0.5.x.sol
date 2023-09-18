pragma solidity ^0.5.2;

contract Auction{
    //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    
    //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
    address payable public highestBidder;
    
    mapping(address => uint) public bids;
    
    uint bidIncrement;
    

    constructor() public{
        owner = msg.sender;
        auctionState = State.Running;
        
        startBlock = block.number;
        endBlock = startBlock + 3;
      
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
    }
    
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
    
    
    //a pure function neither reads nor writes to the blockchain
    function min(uint a, uint b) pure internal returns(uint){
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    //cancel, only by owner
    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }
    
    
    function placeBid() public payable notOwner afterStart beforeEnd returns(bool){
        require(auctionState == State.Running);
       //require(msg.value > 0.001 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        
        require(currentBid > highestBindingBid);
        
        bids[msg.sender] = currentBid;
        
        if (currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
             highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
             highestBidder = msg.sender;
        }
    return true;
    }
    
    
    
    function finalizeAuction() public{
       //the auction has been Ended or Canceled
       require(auctionState == State.Canceled || block.number > endBlock); 
       
       require(msg.sender == owner || bids[msg.sender] > 0);
       
       //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
       address payable recipient;
       uint value;
       
       if(auctionState == State.Canceled){ //canceled not ended
           recipient = msg.sender;
           value = bids[msg.sender];
       }else{//ended not canceled
           if(msg.sender == owner){ //the owner finalizes the auction
               recipient = owner;
               value = highestBindingBid;
           }else{//another user finalizes the auction
               if (msg.sender == highestBidder){
                   recipient = highestBidder;
                   value = bids[highestBidder] - highestBindingBid;
               }else{//this is neiher the owner nor the highest bidder
                   recipient = msg.sender;
                   value = bids[msg.sender];
               }
           }
       }
       
       //sends value to the recipient
       recipient.transfer(value);
        
    }

}


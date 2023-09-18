//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
 
 
contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
   
 
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    
    
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;
    
    
    bool public ownerFinalized = false;
 
    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        
        startBlock = block.number;                    
        endBlock = startBlock + 40320;
      
    //ipfsHash = "";
        bidIncrement = 100; 
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
    
    
    
    function min(uint a, uint b) pure internal returns(uint){
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    
    function cancelAuction() public beforeEnd onlyOwner{
        auctionState = State.Canceled;
    }
    
    
    
    function placeBid() public payable notOwner afterStart beforeEnd returns(bool){
       
        require(auctionState == State.Running);
        
        
        uint currentBid = bids[msg.sender] + msg.value;
        
       
        require(currentBid > highestBindingBid);
        

        bids[msg.sender] = currentBid;
        
        if (currentBid <= bids[highestBidder]){ 
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{ 
             highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
             highestBidder = payable(msg.sender);
        }
    return true;
    }
    
    
    
    function finalizeAuction() public{
       
       require(auctionState == State.Canceled || block.number > endBlock); 
       
       
       require(msg.sender == owner || bids[msg.sender] > 0);
       
       
       address payable recipient;
       uint value;
       
       if(auctionState == State.Canceled){ 
           recipient = payable(msg.sender);
           value = bids[msg.sender];
       }else{
           if(msg.sender == owner && ownerFinalized == false){ 
               recipient = owner;
               value = highestBindingBid;
               
               
               ownerFinalized = true; 
           }else{
               if (msg.sender == highestBidder){
                   recipient = highestBidder;
                   value = bids[highestBidder] - highestBindingBid;
               }else{
                   recipient = payable(msg.sender);
                   value = bids[msg.sender];
               }
           }
       }
       

       
       
       recipient.transfer(value);
     
    } 
}

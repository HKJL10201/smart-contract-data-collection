//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
 
 
// this contract will deploy the Auction contract
contract AuctionCreator{
    // declaring a dynamic array with addresses of deployed contracts
    Auction[] public auctions; 
    
    // declaring the function that will deploy contract Auction
    function createAuction() public{
        
        // passing msg.sender to the constructor of Auction 
        Auction newAuction = new Auction(payable(msg.sender)); 
        auctions.push(newAuction); // adding the address of the instance to the dynamic array
    }
}
 
 
 
contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
 
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    
    
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;
    
 
    constructor(address payable eoa){
        owner = eoa;
        auctionState = State.Running;
        
        startBlock = block.number;
        endBlock = startBlock + 3;
      
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
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
       
       //sends value to the recipient
       recipient.transfer(value);
     
    }
 
}

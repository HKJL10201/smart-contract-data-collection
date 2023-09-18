//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.6.0 <0.9.0;
 
 
contract AuctionCreator{
    Auction[] public auctions;
    
    function createAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    enum State{Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;
    
    mapping(address => uint) public bids;
    
    uint bidIncrement;
    
    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;//a new block is edit/create every 15 seconds
        endBlock = startBlock + 3;// 40320; // = 1 week
        ipfsHash = "";
        bidIncrement = 1000000000000000000; //100;
    }
    
    modifier notOwner(){
        require(msg.sender != owner, "ownner cannot bid");
        _;
    }
    
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock, "after endBlock");
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "you re not the owner");
        _;
    }
    
    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }
    
    function min(uint a, uint b) pure internal returns(uint){
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running, "Action is not Running");
        require(msg.value >= 100, "value to add < 100");
        
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "currentBid <= highestBindingBid");
        
        bids[msg.sender] = currentBid;
        
        if (currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
            
        }
    }
    
    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock, "not finalize: not canceled not endBlock");
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address payable recipient;
        uint value;
        
        if (auctionState == State.Canceled){ // auction was canceled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ // auction ended
            if (msg.sender == owner){ // this is the owner
                require(highestBindingBid > 0, "highestBindingBid == 0, owner has been paid already");
                recipient = payable(owner);
                value = highestBindingBid;
                highestBindingBid = 0;
            }else{ // this is a bidder
                 if (msg.sender == highestBidder) {
                    recipient = payable(highestBidder);
                    value = bids[highestBidder] - highestBindingBid;
                }else{
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[recipient] = 0; // avoid cheater !
        recipient.transfer(value);
    }
}

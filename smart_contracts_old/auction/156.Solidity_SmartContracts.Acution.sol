// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//contract for deploying existing Auction to other product by anyone
//By using this contract, any user can has his own acution

contract AuctionCreator{
    Auction[] public auctions; // can store all the acutions
    
    function createAuction() public {
        Auction newAuction = new Auction(msg.sender); // who ever want acution, they will become owner of the Auction
        auctions.push(newAuction);
    }
}


contract Auction{
    
    address payable public owner;
    uint public startBlock; // auction start
    uint public endBlock; //auction end 
    string public ipfsHash; // item descripiton stored as hash of the item
    
    enum State {started, ended, running, cancelled}
    State public auctionState;
    
    uint public highestBiddingBid;
    address payable public higestBidder;
    
    mapping(address => uint) public bids;
    uint bidIncrement;
    
    constructor(address eoa){ // the owner will be who ever deploying this contract
        owner = payable(eoa); // Converted to payable as owner declared as payable
        auctionState = State.running;
        startBlock = block.number;
        endBlock = startBlock + 3;  // Want to run the auction for one week and the block has been mining for every 15 sec that means approx 40K+ blocks will be mined per week
        ipfsHash = "";
        bidIncrement = 1000000000000000000; //wei
    }
    
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier aferStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    
    function min(uint a, uint b) pure internal returns(uint){
        if( a <= b){
            return a;
        }
        else{
            return b;
        }
    }
    
    function placeBid() public payable notOwner aferStart beforeEnd {
        require(auctionState == State.running);
        require(msg.value >= 100); // min bid 100 wei
        
        uint bidamount = bids[msg.sender] + msg.value; // if user already bidded then we will udpate with increment value, front end should manage how to get increment bid value from existing value and new value, if first time it's like 0 + value
        require(bidamount > highestBiddingBid, "There is a higest bid already!!!");
        
        bids[msg.sender] = bidamount;
        
        if (bidamount <= bids[higestBidder]) {
            highestBiddingBid = min(bidamount + bidIncrement, bids[higestBidder]);
        }
        else{
            highestBiddingBid = min(bidamount, bids[higestBidder] + bidIncrement);
            higestBidder = payable(msg.sender); 
        }
        
    }
    
    //cencell the bid due to unforeseen situations
    function cancelBid() public onlyOwner{
        auctionState = State.cancelled;
    }
    
    
    //finalizethe the bid implementd based on withdrawl pattern
    // i.e. each individual including owner and participants must call withdrawl function to get their amount
    // this is implemented to avoid any attacks after DoV's attack, 
    // however, this functionality may implemented in forntend DApp to call this function for all participants
    
    function finalizeAuction() public {
        require(auctionState == State.cancelled || block.number >= endBlock ); //either cancel or auction ended
        require(msg.sender == owner || bids[msg.sender] > 0);  // either owner or one of the participants
        
        address payable recipient;
        uint value;
        
        // if cancelled, return user's amount
        if(auctionState == State.cancelled){
           recipient = payable(msg.sender); 
           value = bids[msg.sender];
        }
        else{ 
            //if acution ssucces, then owner will take highestBiddingBid eth and give respecive goods to the winner
            if(msg.sender == owner){
                recipient = payable(owner);
                value = highestBiddingBid;
            }
            else{
                //return extra amout to the higestBidder, exatra eth is min of highestBiddingBid and user's bid
                if(msg.sender == higestBidder){
                    recipient = higestBidder;
                    value = bids[higestBidder] - highestBiddingBid;
                }
                else{
                    //rest of the users to get their eth back
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
                
            }
            
        }
        
        //set recipient balance to zero 
        bids[recipient] = 0; // so when they called 2nd time the above method failed bids[recipient] > 0, also there are other methods like remove from the bids
        
        // send the value to respecive recipient
        recipient.transfer(value);
        
    }
    
}
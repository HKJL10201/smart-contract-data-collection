//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

/*
*@author Alain Perez
*@tittle Auction
*/

contract Auction{
    
    address payable public owner; //owner of the contract
    uint public startBlock; //start block to determine time
    uint public endBlock; // end block to determine end time
    string public ipfsHash; //inter planitary file system hash to store block data
    
    //@dev enum to keep track of auctionState
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    mapping(address => uint) public bids;
    
    uint public highestBiddingBid; //The selling price of the item
    address payable public highestBidder;
    
    uint bidIncrement; //make it private so that nobody knows the bidIncrement
    
    /*
    * @dev end block is hard coded to a week of time in mining time, please change if this is not your desired time
    * @notice makes owner the deployer of the contract and makes Auction state to running. 
    */
    constructor(){
        owner = payable(msg.sender); // sets the contract to the owner
        auctionState = State.Running; //sets the auctionState to Running
        
        startBlock = block.number;
        endBlock = startBlock + 40320;//since it takes 15 seconds for the blockchain to mine each block , we can calculate the amount of time it will take to end auction 1 week
        ipfsHash = "";
        bidIncrement = 100;
    }
    
    //@notice makes sure only owner can use this function
    modifier onlyOwner() {
        require(owner == msg.sender,"Requires Admin Privilages");
        _;
    }
    
    //@notice makes sure the owner CANT use the function
    modifier notOwner(){
        require(msg.sender != owner , "The owner cant take part");
        _;
    }
    
    //@notice makes sure the auction has already started 
    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }
    
    //@notice beofr ethe auction ends
    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }
    
    
    //@notice autcion is Canceled
    //@dev the only can only access
    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }
    
    
    //@finds rim between two uint
    function min(uint a, uint b) pure internal returns(uint) {
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    /*
    * @dev makes sure the auction is running and that the bid is larger then 100 wei  and higher then current bid
    * @notice allows users to place bid
    */
    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running , "Auction not curently running"); // makes sure that the action is running
        require(msg.value >= 100); //100 wei being the minimum
        
        uint currentBid = bids[msg.sender] + msg.value; // this tracks how much each address has per address
        
        require(currentBid > highestBiddingBid); //by default is 0
        
        bids[msg.sender] = currentBid; //if we do it this way i fear that msg.value from previous call will be lost
        
        if(currentBid <= bids[highestBidder]){ // if the incoming bid is smaller then that of the highest bidder.
            highestBiddingBid = min(currentBid + bidIncrement , bids[highestBidder]);
        }else{ //if the incoming bid is larger then that of the highest bidder
            highestBiddingBid = min(currentBid , bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
    
    /*
    * @dev makes sure that the auction is not canceled and we have reached the end of timeline
    * @notice selects the winner based on highest bidder and sends the value. Also return value to users who did not win bid
    */
    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0 );
        
        address payable recipient;
        uint value;
        
        if(auctionState == State.Canceled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ //action Ended (   not canceled  )
            if(msg.sender == owner){
                recipient = owner;
                value = highestBiddingBid;
            }else{ // not the owner
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBiddingBid;
                }else{ // neither the owner or the highest bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        
        
        //will not be allowed to call the finalizeAuction again since his bid will be 0
        bids[recipient] = 0;
        //transfer correct amount to designated candidate
        recipient.transfer(value);
        
    }
    
    
    
    
    
}


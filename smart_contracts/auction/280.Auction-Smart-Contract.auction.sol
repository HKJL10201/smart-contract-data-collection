// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction{

    // Auctioner (The one who is conduction the auction) 
    address payable public auctioneer; 
    

    // We need to put a timer for the auction so we will make use of 
    // block as 1 block takes 15 seconds thus we can roughly extimate the start and the end time 

    uint public strtBlock; // start time 
    uint public endBlock; // end time 

    // We neet to know the state of the auction (Started, running , ended, cancelled) 
    // Enum should be used for it 

    enum Auc_State{Started, Running, Ended, Cancelled}
    Auc_State public auctionState;

    //We need to create some variables for  highestpayablebid, bid increment

   
    uint public highestPayableBid;
    uint public bidIncrement; 

    // The one who will be bid the highest 
    address payable public highestBidder; 

    // Mapping to store the bid amount against a bidder address 

    mapping (address => uint) public bids; 


    // Cunstructor to set basic informations. 

    constructor(){
        auctioneer = payable(msg.sender);
        auctionState = Auc_State.Running;
        strtBlock = block.number;
        endBlock = strtBlock + 240; // can modify this to take the input for the auction time 
        bidIncrement = 1 ether; 

    }

     
    // Modifer for the function 
    modifier Owner(){
        require(msg.sender == auctioneer);
        _;
    }

    modifier notOwner(){
        require(msg.sender != auctioneer," Owner cannot Bid");
        _;
    }

    //This is to check whether the auction is on or not 
    modifier AuctionisON(){
        require(block.number>strtBlock && block.number< endBlock,"The Auction is not Running");
        require(auctionState == Auc_State.Running, "Auction might be cancelled");
        _;
    } 




    // ################ FUNCTIONS #################

    // Minimum Function 
     function min(uint _a, uint _b) private pure returns (uint )
     {
        return _a <= _b ? _a : _b;
     }

    // Cancel Function for the auctioneer 
    function cancelAuction() public Owner{
        auctionState = Auc_State.Cancelled;
    }

    
    // Function for bidding 

    function bid() payable public notOwner AuctionisON  {
        require(msg.value >= 1 ether, "Please Enter valid Amount");

        uint currentBid  = bids[msg.sender] + msg.value ;

        require(currentBid > highestPayableBid);

        bids[msg.sender] = currentBid;

        if(currentBid<bids[highestBidder])
        {
            highestPayableBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else
        {
            highestPayableBid = min(currentBid , bids[highestBidder] + bidIncrement);
            highestBidder = payable (msg.sender);
        }


    }

    // Function to get the bid amout from the contract 
    
    function finalizeAuction() public { 
        require(auctionState == Auc_State.Cancelled || block.number > endBlock, "The Auction has Already Ended");
        require(msg.sender == auctioneer || bids[msg.sender] > 0);

        address payable person;
        uint value; 

        if(auctionState == Auc_State.Cancelled)
        {
            person = payable(msg.sender);
            value = bids[msg.sender];
        }
        else
        {
            if(msg.sender == auctioneer)
            {
                person = auctioneer;
                value = highestPayableBid;
            }
            else
            {
                if(msg.sender == highestBidder)
                {
                    person = highestBidder;
                    value = bids[highestBidder] - highestPayableBid; 
                }
                else
                {
                    person = payable (msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender]= 0; // This will not allow the smart contract to be exploited by someone (reenterancy Attack)
        person.transfer(value);
    }

}
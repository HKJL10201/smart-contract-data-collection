// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction{
    // Auctioneer public person with address
    address payable public Auctioneer;
    
    // starting and ending block for time reference
    uint public stblock;
    uint public enblock;

    //enum for knowing the status
    enum Auc_State {Started, Running, Ended, Cancelled}
    Auc_State public auctionstate;
    
    //bidding type
    uint public highestBid;
    uint public highestPayableBid;
    uint public bidIncreament;

    //highest Bidder
     address payable public highestBidder;

    //bidders -> mapping
    mapping (address=>uint) public bids;

    //Initialise with Constructer
    constructor(){
        Auctioneer= payable(msg.sender);
        auctionstate= Auc_State.Running;
        bidIncreament=1 ether;
        stblock= block.number;
        enblock=stblock+240;
    }


    //condition / modifier
    modifier notOwner(){
    require(msg.sender!=Auctioneer,"Owner cannot bid");
    _;
    }
    //condition-2
    modifier Owner(){
    require(msg.sender==Auctioneer,"Owner cannot bid");
    _;
    }
    //condition-3
    modifier started(){
    require(block.number>stblock);
    _;
    }
    //condition-4
    modifier beforeEnding(){
    require(block.number<enblock);
    _;
    }
    function AucCancelled() public Owner{
        auctionstate=Auc_State.Cancelled;
    } 
    function AucEnded() public Owner{
        auctionstate=Auc_State.Ended;
    }
    function min(uint a, uint b) pure private returns(uint){
        if(a>=b){
            return b;
        }
        else{
            return a;
        }
    }


    //function for implementation
    function bid() payable  public notOwner started beforeEnding{
        //condition required
        require(auctionstate == Auc_State.Running);
        require(msg.value >= 1 ether);
        
        //Currentbid Initialization
        uint currentBid= bids[msg.sender]+msg.value;

        //condition check for currentbid
        require(currentBid>highestPayableBid);

        bids[msg.sender]= currentBid;
        
        
        //updating the highestPayableBid
        if(currentBid<bids[highestBidder]){
            highestPayableBid= min(currentBid+bidIncreament,bids[highestBidder]);
        }
        else{
            highestPayableBid= min(currentBid,bids[highestBidder]+bidIncreament);
            highestBidder=payable(msg.sender);
        }
    }

    function finalizeAuc() public{
        require(auctionstate== Auc_State.Cancelled||auctionstate== Auc_State.Ended || block.number>enblock);
        require(msg.sender==Auctioneer || bids[msg.sender]>0);
        
        address payable person;
        uint value;
        // condition for who will get the amount
        if(auctionstate==Auc_State.Cancelled){
            person=payable (msg.sender);
            value= bids[msg.sender];
        }
        else {
            if(msg.sender==Auctioneer){
                person= Auctioneer;
                value=highestPayableBid;
            }
            else {
                if(msg.sender==highestBidder){
                    person=highestBidder;
                    value= bids[highestBidder]-highestPayableBid;
                }
                else{
                    person=payable (msg.sender);
                    value=bids[msg.sender];
                }
            }
        }
        //reset bids[] not to exploit
        bids[msg.sender]=0;
        person.transfer(value);

    }

}


//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction{
    address payable public  auctioneer;
    uint public stblock;
    uint public etblock;
    enum Auc_State {Started, Running, Ended, Cancelled}
    Auc_State public auctionerState;
    uint public highestBid;
    uint public hightestPayableBid;
    uint public bidInc;
    address payable public  hightestBidder;
    mapping(address => uint) public bids;
    constructor(){
        auctioneer = payable(msg.sender);
        auctionerState = Auc_State.Running;
        stblock = block.number;
        etblock = stblock + 240;
        bidInc = 1 ether;

    }

   modifier notOwner(){
       require(msg.sender != auctioneer, "owner can't bid");
       _;
   }
   modifier Owner(){
       require(msg.sender == auctioneer,"only owner");
       _;
   }
   modifier started(){
       require(block.number > stblock);
       _;
   }

   modifier beforeEnding(){
       require(block.number < etblock);
       _;

   }

   function cancelAuc() public Owner {
       auctionerState= Auc_State.Cancelled;
   }

   function min(uint a, uint b) pure private returns(uint){
       if(a<b)
       return a;
       else 
       return b;
   }

   function bid() payable public notOwner started beforeEnding {
       require(auctionerState == Auc_State.Running);
       require(msg.value >=  1 ether);
       uint currentBid = bids[msg.sender]+msg.value;
       require(currentBid > hightestPayableBid);
       bids[msg.sender] = currentBid;
       if(currentBid < bids[hightestBidder]){
           hightestPayableBid = min(currentBid + bidInc,bids[hightestBidder]);
       }
       else{
       hightestPayableBid = min(currentBid,bids[hightestBidder]+ bidInc);
       hightestBidder = payable(msg.sender);
       }
   }

   function finalizeAuc() public  {
       require(auctionerState == Auc_State.Cancelled || block.number > etblock);
       require(msg.sender == auctioneer || bids[msg.sender] > 0);
       address payable person;
       uint value;
       if(auctionerState == Auc_State.Cancelled){
           person = payable(msg.sender);
           value = bids[msg.sender];
       }
        else{
            if(msg.sender == auctioneer){
                person = auctioneer;
                value = hightestPayableBid;
                
            }

            else {
                if(msg.sender == hightestBidder){
                    person = hightestBidder;
                    value = bids[hightestBidder] - hightestPayableBid;
                }
                else{
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(value);
   }

}
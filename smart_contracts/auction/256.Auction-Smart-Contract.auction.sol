//SPDX-License-Identifier:MIT;

pragma solidity ^0.8.7;
contract Auction{
    address payable public owner;
    uint public auctionEndTime;
      uint  fee = 0.1 * 10 ** 18; // 0.1 ether (Varies by network);
    address public highestBidder;
    uint public highestBid;
    

  mapping(address => uint) pendingReturns;

  bool ended = false;

  event highestBidIncrease(address Bidder, uint amount);
  event AuctionEnded (address Winner, uint amount);

  constructor(uint _biddingTime, address payable _owner){
  owner = _owner;
  auctionEndTime = block.timestamp + _biddingTime;
   
  }

  function bid() public payable{
      require(msg.value >= fee, "insufficient balance");
      if (block.timestamp > auctionEndTime){
         revert("the auction has already ended");
     }
     if (msg.value <= highestBid){
         revert("there is already a higher or equal bid");
     }

     if (highestBid != 0){
         pendingReturns[highestBidder] += highestBid;
     }

     highestBidder = msg.sender;
     highestBid = msg.value;

     emit highestBidIncrease(msg.sender, msg.value);

  }
 modifier exceptWinner(){
       require (msg.sender != highestBidder, 'you are the highestBidder');
       _;
   }
  function withdraw() public exceptWinner returns(bool){
   uint amount = pendingReturns[msg.sender];
   if (amount > 0){
       pendingReturns[msg.sender] = 0;
       
     if (!payable (msg.sender).send(amount)){
     pendingReturns[msg.sender] = amount;
     return false;
     }
    }
    return true;
  }
  
  function endAuction() public{
     if (block.timestamp < auctionEndTime){
         revert("auction has not ended");
     }
     if (ended){
         revert("auction has ended");
     }
     ended = true;
     emit AuctionEnded(highestBidder, highestBid);

  }
}
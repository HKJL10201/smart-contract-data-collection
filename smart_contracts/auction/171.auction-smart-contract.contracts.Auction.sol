// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Auction {
  address private owner;
  uint public startTime;
  uint public endTime;


  mapping(address => uint) public bids;


  struct HighestBid {
    uint bidAmount;
    address bidder;
  }


  HighestBid public highestBid;


  event LogBid(address indexed _highestBidder, uint _highestBid);
  event LogWithdrawal(address indexed _withdrawer, uint amount);


  constructor () {
    owner = msg.sender;
    startTime = block.timestamp;
    endTime = block.timestamp +  2 minutes;
  }


  function makeBid() public payable isOngoing() notOwner() returns (bool) {
   uint bidAmount = bids[msg.sender] + msg.value;
   require(bidAmount > highestBid.bidAmount, 'Bid error: Make a higher Bid.');

   highestBid.bidder = msg.sender;
   highestBid.bidAmount = bidAmount;
   bids[msg.sender] = bidAmount;
   emit LogBid(msg.sender, bidAmount);
   return true;
 }

  function withdraw() public notOngoing() notHighestBidder() returns (bool) {
    require(msg.sender == owner || bids[msg.sender] > 0);

    address payable recipiant;
    uint value;

    if(msg.sender == owner){
      recipiant = payable(owner);
      value = highestBid.bidAmount;
    }
    else {
      recipiant = payable (msg.sender);
      value = bids[msg.sender];
    }

    bids[msg.sender] = 0;
    recipiant.transfer(value);
    return true;
 }


 function fetchHighestBid() public view returns (HighestBid memory) {
   HighestBid memory _highestBid = highestBid;
   return _highestBid;
 }

 function getOwner() public view returns (address) {
   return owner;
 }


modifier isOngoing() {
   require(block.timestamp < endTime, 'This auction is closed.');
   _;
 }
 modifier notOngoing() {
   require(block.timestamp >= endTime, 'This auction is still open.');
   _;
 }
  modifier notHighestBidder() {
   require(msg.sender != highestBid.bidder, 'Highest bidder can not withdraw.');
   _;
 }
 modifier isOwner() {
   require(msg.sender == owner, 'Only owner can perform task.');
   _;
 }
 modifier notOwner() {
   require(msg.sender != owner, 'Owner is not allowed to bid.');
   _;
 }

}
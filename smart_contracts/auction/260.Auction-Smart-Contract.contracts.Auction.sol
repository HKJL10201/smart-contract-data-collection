// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AuctionCreator{
  Auction[] public auctions;

  function createAuctions() public{
    Auction newAuction =  new Auction(msg.sender);
    auctions.push(newAuction);
  }
}

contract Auction {

  address payable public owner;
  uint public startBlock;
  uint public endBlock;
  string public ipfsHash;

  enum State {Started, Running, Ended, Cancelled}
  State public auctionState;

  uint public highestBindingBid;
  address payable public highestBidder;

  mapping(address => uint) public bids;
  uint bidIncrement;

  constructor(address eoa) {
    owner = payable(eoa);
    auctionState = State.Running;
    startBlock = block.number; 
    endBlock =  startBlock + 40320; //+3
    ipfsHash = '';
    bidIncrement = 100;
  }

  modifier notOwner() {
    require(owner != msg.sender, 'owner cant call this function');_;
  }

  modifier afterStart() {
    require(block.number >= startBlock, '');_;
  }

  modifier beforeEnd() {
    require(block.number <= endBlock, '');_;
  }

  modifier onlyOwner(){
    require(msg.sender == owner, 'only owner can call this function');_;
  }

  function min(uint a, uint b) pure internal returns(uint){
    if(a <= b ){
      return a;
    }else{
      return b;
    }
  }

  function cancelAuction() public onlyOwner {
    auctionState = State.Cancelled;
  }

  function placeBid() public payable notOwner afterStart beforeEnd returns(bool) {
    require((auctionState == State.Running));
    require(msg.value >= 100);

    uint currentBid = bids[msg.sender] + msg.value;
    require((currentBid > highestBindingBid), 'Bid must higher then Highest Bid');

    bids[msg.sender] = currentBid;

    if(currentBid < bids[highestBidder]){

      highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);

    }else{

      highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
      highestBidder = payable(msg.sender);

    }

    return true;

  }

  function finalizeAuction() public{

    require(auctionState == State.Cancelled || block.number > endBlock);
    require(msg.sender == owner || bids[msg.sender] > 0);

    address payable recipient;
    uint value;

    if(auctionState == State.Cancelled){
      recipient = payable(msg.sender);
      value = bids[msg.sender];
    }else{
      if(msg.sender == owner){
        recipient = owner;
        value = highestBindingBid;
      }else{

        if(msg.sender == highestBidder){
          recipient = highestBidder;
          value = bids[highestBidder] - highestBindingBid;
        }else{
          recipient = payable(msg.sender);
          value = bids[msg.sender];
        }
      }
    }

    bids[recipient] = 0;

    recipient.transfer(value);
  }
}

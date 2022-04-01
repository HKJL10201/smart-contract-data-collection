//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4;


contract auctionCreator {
  Auction[] public auctions;

  function createAuction() public {
    Auction newAuction = new Auction(msg.sender);
    auctions.push(newAuction);
  }
}

contract Auction {
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

    constructor(address _owner){
      owner = payable(_owner);
      auctionState = State.Running;
      startBlock = block.number;
      endBlock = startBlock + 40320; // One week
      ipfsHash = "";
      bidIncrement = 100;
    }

    modifier notOwner(){
      require(msg.sender != owner, 'As a owner you cannot execute this function');
      _;
    }

    modifier afterStart(){
      require(block.number >= startBlock, 'This auction hasnt started yet');
      _;
    }

    modifier beforeEnd(){
      require(block.number <= endBlock, 'This auction has already ended');
      _;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, 'You are not the owner of the auction');
      _;
    }

    function getBidIncrement() external view onlyOwner returns (uint) {
      return bidIncrement;
    }

    function cancelAuction() public onlyOwner {
      auctionState = State.Canceled;
    }

    function min(uint a, uint b) pure internal returns (uint){
      if(a <= b){
        return a;
      } else {
        return b;
      }
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
      require(auctionState == State.Running, 'Auction is not running');
      require(msg.value >= 100, 'Minimum bid is 100 wei');

      uint currentBid = bids[msg.sender] + msg.value;
      require(
        currentBid > highestBindingBid,
        'Current bid must be higher than highestBindingBid'
      );

      if(currentBid <= bids[highestBidder]){
        highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
      } else {
        highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
        highestBidder = payable(msg.sender);
      }

      bids[msg.sender] = currentBid;
    }

    function finalizeAuction() public {
      require(
        auctionState == State.Canceled || block.number > endBlock,
        'Auction must be canceled or finished'
      );

      require(
        msg.sender == owner || bids[msg.sender] > 0,
        'Only owner or bidder can finalize the auction'
      );

      address payable recipient;
      uint value;

      if(auctionState == State.Canceled) { // auction was canceled
        recipient = payable(msg.sender);
        value = bids[msg.sender];
      } else { // auction has ended
        if(msg.sender == owner){
          recipient = owner;
          value = highestBindingBid;
        } else {
          if(msg.sender == highestBidder) {
            recipient = highestBidder;
            value = bids[highestBidder] - highestBindingBid;
          } else {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
          }
        }
      }
      bids[recipient] = 0;
      recipient.transfer(value);
    }

}

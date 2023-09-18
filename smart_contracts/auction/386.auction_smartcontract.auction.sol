// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator{
  Auction [] public auctions;

function createAuction () public{
    Auction newAuction = new Auction (msg.sender); //newAuction, the name of the variable equals new auction create, pass msg.sender and modify the constructor
    auctions.push (newAuction);//add address of the dynamic array of the contract address, not the EOA.
  }
}


contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping (address => uint) public bids;
    uint bidIncrement;

    constructor(address eoa) { //addd the new paramaeter address eoa
      owner = payable(eoa); // and owner is payabel of eoa.
      auctionState = State.Running;
      startBlock = block.number;
      endBlock = startBlock + 3;
      ipfsHash = "";
      bidIncrement = 1000000000000000000;

    }

    modifier notOwner () {
        require(msg.sender != owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }


    modifier beforeEnd () {
        require(block.number <= endBlock);
        _;
    }


    modifier onlyOwner (){
    require(msg.sender == owner);
    _;
    }


    function cancelAuction () public payable onlyOwner {
    auctionState = State.Canceled;
    }



    function min(uint a, uint b) pure internal returns (uint) {
        if (a <= b){
            return a;
        } else {
            return b;
        }
    }


    function placeBid() public payable notOwner afterStart beforeEnd {
        require (auctionState == State.Running);
        require (msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require (currentBid > highestBindingBid);

        bids [msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]){
            highestBindingBid = min (currentBid + bidIncrement, bids [highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }

    }






    function finalizeAuction () public {
        require(auctionState == State.Canceled || block.number > endBlock );
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if (auctionState == State.Canceled){ //auction was cancelled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else  { //auctionended (not canceled);
            if (msg.sender == owner) { //this is the owner rightfully getting the highestBindingBid
                recipient = owner;
                value = highestBindingBid;
            } else { //the address that finalizes the auction is not the owner, but a bidder who requests his own funds.
                if (msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];

                 }

             }
        }

        //resetting the bids of the recipient to zero;
        bids[recipient] = 0;

        //sends value to the recipient

         recipient.transfer(value);

      }

}
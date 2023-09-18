//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State{
        Started,
        Running,
        Ended,
        Cancled
    }
    State public auctionState;
    uint public highestBiddingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    function min(uint a, uint b) internal pure returns(uint){
        if(a <= b) {
            return a;
        }
        return b;
    }
    function cancleAuction() public onlyOwner{
        auctionState = State.Cancled;
    }
    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBiddingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]) {
            highestBiddingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else {
            highestBiddingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
    function finilizeAuction() public {
        require(auctionState == State.Cancled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Cancled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
        else{
            if(msg.sender == owner){
                recipient = payable(owner);
                value = highestBiddingBid;
            }
            else{
                if(msg.sender == highestBidder){
                    recipient = payable(highestBidder);
                    value = bids[highestBidder] = highestBiddingBid;
                }
                else{
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[recipient] = 0;
        recipient.transfer(value);
    }


}

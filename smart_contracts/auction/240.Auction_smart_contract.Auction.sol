//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator {
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

    uint public highestBindingBid; //selling price
    address payable public highestBidder; //so that the bidder can receive money back if 
                                          //the auction is canceled

    mapping(address => uint) public bids; //mapping the bidder's address & the amount of their bid

    uint bidIncrement;

    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;

        //new block in ethereum is being created every 15 seconds
        //block.number is the current block number & since ethereum creates block every 15 seconds
        //in order to set end time of a week, then have to caculate -> (60 * 60 * 24 * 7) / 15 = 40320 
        startBlock = block.number;
        endBlock = startBlock + 40320; //ending a week later
        ipfsHash = "";
        bidIncrement = 100;
    } //end of constructor

    //RESTRICTIONS: cannot allow the owner to place the bid
    modifier notOwner() {
        require (msg.sender != owner);
        _;
    }

    //The auction only be running within the start & end blocks
    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function cancelAuction() public onlyOwner() {
        auctionState = State.Canceled;

    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value; 
        //bids[msg.sender] is the value the curernt user has sent
        //msg.value = the value sent with the curent transaction

        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0); 
        //only the owner or a bidder can finalize the auction

        if(auctionState == State.Canceled) { //auction was canceled
            payable(msg.sender).transfer(bids[msg.sender]);
        } else { //auction ended (not canceled)
            if(msg.sender == owner) {//this is the owner
                payable(msg.sender).transfer(highestBindingBid);
            } else { //this is a bidder
                //if highest bidder
                if(msg.sender == highestBidder) {
                    uint excess = bids[msg.sender] - highestBindingBid;
                    payable(msg.sender).transfer(excess);
                } else { //neither the owner nor the highestbidder
                    payable(msg.sender).transfer(bids[msg.sender]);
                }

            }
        }
        //resetting the bids of the recipient to zero
        bids[msg.sender] = 0;
    }

}
pragma solidity >=0.5.0 <0.9.0;

contract Auction {

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

    constructor() public {
        owner = msg.sender;
        auctionState = State.Running;

        startBlock = block.number;
        endBlock = startBlock + 7; //40320; We want the auction to last a week and a block is mined in average for 15 sec. One week would be appr 40320 blocks.
        ipfsHash = "";
        bidIncrement = 200000000000000000; // which is 0.2 ether
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) { // The function neither reads from the blockchain nor modifies it. Therefore it is pure.
        if(a <= b) {
            return a;
        }
        else {
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 1 ether);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min((currentBid + bidIncrement), bids[highestBidder]);
        }
        else {
            highestBindingBid = min((bids[highestBidder] + bidIncrement), currentBid);
            highestBidder = msg.sender;
        }

    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) {// The auction was canceled
            recipient = msg.sender;
            value = bids[msg.sender];
        }
        else {// The auction ended not canceled
            if(msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            }
            else {
                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }
                else {// This is neither the owner nor the highest bidder
                    recipient = msg.sender;
                    value = bids[msg.sender];
                }
            }
        }

        recipient.transfer(value);

    }




}

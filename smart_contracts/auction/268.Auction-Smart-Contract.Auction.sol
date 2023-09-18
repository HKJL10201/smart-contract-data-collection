//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Auction{
    address payable public auctioneer;
    //Address of the owner
    uint public  startTimeBlock;
    //Starting time of the Block
    uint public  endTimeBlock;
    //Ending time of the Block

    enum State{
        Started,
        Running,
        Ended,
        Cancelled
    }
    State public auctionState;

    uint public highestPayableBid;
    //This indicates that your total needs to be more than this to win

    uint public bidIncrement;
    //Minimum increment to do if you want to become the highest Bidder
    //Which is 10000 wei

    address payable public highestBidder;
    //Address of the highest bidder

    mapping (address => uint) internal bids;

    constructor(uint timeInHours){
        auctioneer = payable(msg.sender);
        auctionState = State.Running;

        startTimeBlock = block.number;
        endTimeBlock = block.number +  (timeInHours * 240);
        //Here the logic is each block is made after every 15 seconds. It means 1 miute = 4 block
        //Therefore 1 hour = 60 minutes = 4 blocks * 60 minutes = 240 blocks

        bidIncrement = 10000;
    }

    modifier notOwner(){
        require(msg.sender != auctioneer, "Auctioneer cannot bid");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == auctioneer, "Only Auctioneer have access to this");
        _;
    }

    modifier auctionIsOn(){
        require(block.number > startTimeBlock, "Auction have not started yet");
        require(block.number < endTimeBlock, "Auction is ended");
        _;
    }

    function min(uint _a, uint _b) internal pure returns (uint )
        {
            return _a <= _b ? _a : _b;
        }
    function max(uint _a, uint _b) internal pure returns (uint )
        {
            return _a >= _b ? _a : _b;
        }

    function bid()public payable notOwner auctionIsOn{
        require(auctionState == State.Running, "There aren't any auctions going on");
        require(msg.value >= 10000, "Minimum amount should be greater than 10000 wei");
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestPayableBid, "Your bid is lower than the highest bid");
        bids[msg.sender] = currentBid;
        if(currentBid < bids[highestBidder]){
            highestPayableBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestPayableBid = max(currentBid , highestPayableBid);
            highestBidder = payable(msg.sender);
        }
    }
    //This function is to do bidding 

    function finalizeAuc() public {
        require(auctionState == State.Cancelled || auctionState == State.Ended ||block.number > endTimeBlock, "Auction is still in process");
        require(msg.sender == auctioneer || bids[msg.sender] > 0,"You haven't participated in the auction");
        address payable person;
        uint value;
        if (auctionState == State.Cancelled){
            person = payable(msg.sender);
            value = bids[msg.sender]; 
        } else {
            if (msg.sender == auctioneer){
                person = auctioneer;
                value = highestPayableBid;
            } else {
                if (msg.sender == highestBidder){
                    person = highestBidder;
                    value = bids[highestBidder] - highestPayableBid;
                } else {
                    person = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        person.transfer(value);
    }
    //This function is used to get the money

    function cancelAuc()public onlyOwner {
        auctionState  = State.Cancelled;
    }

    function endAuc()public onlyOwner{
        auctionState  = State.Ended;
    }

    function yourTotalBid()public view notOwner returns(uint){
        return bids[msg.sender];
    }
}
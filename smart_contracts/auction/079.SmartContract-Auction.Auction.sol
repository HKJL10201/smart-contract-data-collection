//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract Creator {
    address public ownerCreator;
    Auction[] public deployedAuction;

    constructor(){
        ownerCreator = msg.sender;
    }

    function deployAuction() public{
        Auction new_Auction_Address = new Auction(msg.sender);
        deployedAuction.push(new_Auction_Address);
    }

}

contract Auction {
    address payable public owner;
    //its not safe to use block.timestamp as a timer since the miner can spoof the block timestamp
    uint public startBlock;
    uint public endBlock;
    uint public MinimumBidValue;
    string public ipfsHash;

    enum State{
        Started,
        Running, 
        Ended,
        Canceled
    }
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    //when initiating contract, it will be in ENDED state
    constructor(address _contractOwner){
        owner = payable(_contractOwner);
        auctionState = State.Started;
    }

    function isOwner(address _address) internal view returns(bool){
        return _address == owner;
    }

    //can only start new bid when the old one are already Ended
    //assuming we want to run the auction once per week 
    //the it'll be (60s * 60m *24h *7d)/15s = 40,320 blocks. 1 block in ethereum are generated per 15s
    function startNewBid(uint blocksGenerated, uint BidIncrementWei, uint _MinimumBidValue) public onlyOwner isStarted{
        startBlock = block.number;
        endBlock = startBlock + blocksGenerated;
        auctionState = State.Running;
        ipfsHash = "";
        bidIncrement = BidIncrementWei;
        MinimumBidValue = _MinimumBidValue;
    }

    function min(uint a, uint b) internal pure returns(uint){
        if(a<=b){
            return a;
        }else {
            return b;
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;

    }

    //msg.value is the maximum amount the user willing to pay
    function placeBid() public payable notOwnerOrBeneficiary afterStart beforeEnd{
        require(auctionState == State.Running, "Please wait until the auction start");
        require(msg.value >= MinimumBidValue);

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid >= highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number >= endBlock);
        require(isOwner(msg.sender) || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled){ //auction canceled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ //executed when auction ended
            if(isOwner(msg.sender)){
                recipient = payable(owner);
                value = highestBindingBid;
            }else{ //a bidder
                if(msg.sender == highestBidder){ //when highest bidder 
                    recipient = payable(highestBidder);
                    value = bids[msg.sender] - highestBindingBid;
                }else{ //when not highest bidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        bids[recipient] = 0;
        recipient.transfer(value);
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    //so that owner wont raise the bid artificially
    modifier notOwnerOrBeneficiary(){
        require(msg.sender != owner);
        _;
    }

    modifier isStarted(){
        require (auctionState == State.Started);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier isRunning(){
        require( auctionState == State.Running);
        _;
    }
}
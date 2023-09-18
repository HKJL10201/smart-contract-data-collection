pragma solidity ^0.5.1;

contract BlindAuction {
    
    address owner;
    uint honestCounter = 0;
    uint standardDeposite = 5;
    
    // to declare the winner
    uint public winnerIndex;
    address public winnerAddress;

    
    mapping(address => Bid)  bids;
    mapping(address => Tracing) trace;
    mapping(uint => Honest) honestBidders;
    
    // time in seconds
    uint biddingTimeRange = 120;
    uint revealTimeRange = 120;
    uint finalizeTimeRange = 30;
    uint biddingEnd = now + biddingTimeRange;
    uint revealEnd = biddingEnd + biddingTimeRange;
    uint finalizeEnd = revealEnd + finalizeTimeRange;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyAfter(uint _time) { 
        require(now > _time); 
        _; 
    }
    modifier onlyBefore(uint _time) { 
        require(now < _time);
        _; 
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner); 
        _;
    }
    
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }
    
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }
    
    struct Honest {
        address payable bidderAddress;
        uint value;
    }
    
    struct Tracing {
        uint id;
        bool depositeIsBack;
    }
    
    function aBid(bytes32 commit) public payable notOwner onlyBefore(biddingEnd) {
        require (msg.value >= standardDeposite);
        bids[msg.sender] = Bid(commit, msg.value);   
    }

    
    function bReveal(uint nonce) public payable  onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        Bid memory b = bids[msg.sender];

        if (b.blindedBid == keccak256(abi.encode(msg.value, nonce, msg.sender))) {
            honestBidders[honestCounter] = Honest(msg.sender, msg.value);
            trace[msg.sender] = Tracing(honestCounter, false);
            honestCounter++;
        }
    }
    function cFinalize() public payable onlyOwner onlyAfter(revealEnd) onlyBefore(finalizeEnd){
        uint maxBiddingValue = 0;
        
        for (uint i = 0; i < honestCounter; i++) {
            if (honestBidders[i].value > maxBiddingValue) {
                maxBiddingValue = honestBidders[i].value;
                winnerAddress = honestBidders[i].bidderAddress;
                winnerIndex = i;
            }
        }
        
        for (uint i = 0; i < honestCounter; i++) {
            if (honestBidders[i].bidderAddress != winnerAddress) {
                honestBidders[i].bidderAddress.transfer(bids[honestBidders[i].bidderAddress].deposit + honestBidders[i].value);
                trace[honestBidders[i].bidderAddress].depositeIsBack = true;
            }
        }
    }
    
    modifier notWinner() {
        require(msg.sender != winnerAddress);
        _;
    }
    
    // return true if the bidder did not receive his money back
    modifier depositeIsNotBack() {
        require(trace[msg.sender].depositeIsBack == false);
        _;
    }

    // return all deposit and bidding money back if the auction is not vaild (the manager didn't reveal the winner)
    function dWithdrow() public payable notOwner depositeIsNotBack onlyAfter(finalizeEnd) {  
        msg.sender.transfer(bids[msg.sender].deposit + honestBidders[trace[msg.sender].id].value);        
        trace[msg.sender].depositeIsBack = true; 
    }
    
    // helper function used to test the contract
    bytes32 public testCommit;
    function helperCommit(uint value, uint nonce) public payable  {
        testCommit = keccak256(abi.encode(value, nonce, msg.sender));  
    }
}
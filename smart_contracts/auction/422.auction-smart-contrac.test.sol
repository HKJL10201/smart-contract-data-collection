pragma solidity ^0.8.0;

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public item;
    uint public highestBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    bool public ended;
    
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    constructor(
        string memory _item,
        uint _startBlock,
        uint _endBlock
    ) {
        owner = payable(msg.sender);
        item = _item;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyBeforeEnd() {
        require(block.number < endBlock);
        _;
    }
    
    modifier onlyAfterEnd() {
        require(block.number >= endBlock);
        _;
    }
    
    function bid() public payable onlyBeforeEnd {
        require(msg.value > highestBid);
        
        if (highestBid != 0) {
            bids[highestBidder] += highestBid;
        }
        
        highestBidder = payable(msg.sender);
        highestBid = msg.value;
        
        emit HighestBidIncreased(highestBidder, highestBid);
    }
    
    function withdraw() public {
        require(bids[msg.sender] > 0);
        
        uint amount = bids[msg.sender];
        bids[msg.sender] = 0;
        
        if (!payable(msg.sender).send(amount)) {
            bids[msg.sender] = amount;
        }
    }
    
    function endAuction() public onlyOwner onlyAfterEnd {
        require(!ended);
        
        ended = true;
        
        emit AuctionEnded(highestBidder, highestBid);
        
        owner.transfer(highestBid);
    }
}

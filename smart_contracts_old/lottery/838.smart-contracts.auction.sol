// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


contract AuctionCreator{
    Auction[] public auctions;
    
    function createAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    
    enum State {Started, Running, Ended, Canceled}
    State public state;
    
    uint public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;
    
    uint constant numberOfBlocksMinedInWeek = 40320;
    
    constructor(address eoa){
        owner = payable(eoa);
        state = State.Running;
        startBlock = block.number;
        endBlock = startBlock + numberOfBlocksMinedInWeek;
        ipfsHash = "";
        bidIncrement = 100;
    }
    
    modifier notOwner{
        require(msg.sender != owner);
        _;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
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
    
    function min(uint a, uint b) pure internal returns(uint)
    {
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
    
    function cancelAuction() public onlyOwner{
        state = State.Canceled;
    }
    
    function placeBid() public payable notOwner afterStart beforeEnd{
        require(state == State.Running);
        require(msg.value >= 100);
        
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        
        bids[msg.sender] = currentBid;
        
        if (currentBid <= bids[highestBidder])
        {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
    
    function finalizeAuction() public{
        require(state == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address payable recipent;
        uint value;
        
        if (state == State.Canceled){
            recipent = payable(msg.sender);
            value = bids[msg.sender];
        }else{
            if(msg.sender == owner){
                recipent = owner;
                value = highestBindingBid;
            }else{
                if(msg.sender == highestBidder){
                    recipent = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{
                    recipent = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        
        bids[recipent] = 0;
        recipent.transfer(value);
    }
}

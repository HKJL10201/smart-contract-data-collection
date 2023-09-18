pragma solidity ^0.8.7;

contract Auction {
    address payable public owner; 
    uint public startTime; 
    uint public endTime; 

    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;

    uint public highestPayableBid; 
    uint public bidInc; 

    address payable public highestBidder; 

    mapping(address => uint) public bidders; 

    
    constructor(){
        owner = payable(msg.sender);

        auctionState = State.Running;

        startTime = block.number;
        endTime = startTime + 240;

        bidInc = 1 ether;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sorry you are not permitted to use it.");
        _;
    }
    modifier notOwner {
        require(msg.sender != owner, "Owner Can't bid");
        _;
    }

    modifier started {
        require(block.number > startTime);
        _;
    }

    modifier isEnded {
        require(block.number <= endTime);
        _;    
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Cancelled;
    }

    function min(uint first, uint second) pure private returns(uint){
        if(first <= second){
            return first;
        }else{
            return second;
        }
    }

    function placeBid() payable public notOwner started isEnded {
        require(auctionState == State.Running);
        require(msg.value >= 1 ether);

        uint currentBid = bidders[msg.sender] + msg.value;

        require(currentBid > highestPayableBid);

        bidders[msg.sender] = currentBid;

        if(currentBid < bidders[highestBidder]){
            highestPayableBid = min(currentBid+bidInc, bidders[highestBidder]);
        }else {
            highestPayableBid = min(currentBid, bidders[highestBidder] +bidInc);
            highestBidder = payable(msg.sender);
        }

    }

    
    function finalize() public {
        require(auctionState == State.Cancelled || block.number >= endTime);
        require(msg.sender == owner || bidders[msg.sender] > 0);
        
        address payable person;
        uint value;

        if(auctionState == State.Cancelled) {
            person = payable(msg.sender);
            value = bidders[msg.sender];

        }else{
            if(msg.sender == owner){
                person = owner;
                value = highestPayableBid; 
            }else{
                if(msg.sender == highestBidder){
                    person = highestBidder;
                    value = bidders[highestBidder] - highestPayableBid;
                }else{
                    person = payable(msg.sender);
                    value = bidders[msg.sender];
                }
            }
        }
        bidders[msg.sender] = 0;
        person.transfer(value);
    }
}

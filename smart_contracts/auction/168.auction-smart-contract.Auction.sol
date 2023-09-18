pragma solidity ^0.5.0;

/**
 * @title Auction Contract
 * @dev simple auction utilizing the OpenZeppelin framework 
 */

//import "./Ownable.sol";
import "./SafeMath.sol";



contract Auction {
    using SafeMath for uint256;

    
    address public owner;
    address public highestBidder;
    
    uint public bidIncrement;
    uint public highestBindingBid;
    
    uint private startBlock;
    uint private endBlock;

    mapping(address => uint) public bids;
    
    enum State {Started, Running, Ended, Cancelled}
    State public actionState;
    
    /** 
    *   @dev _auctionCreator - address that call CreateAuctionInstance from AuctionCreator
    *        _noOfDaysTorun  - number of days that the auction will run
    */
    constructor(address _auctionCreator, uint _noOfDaysTorun) public {
        owner = _auctionCreator;
        actionState = State.Running;
        uint secondsPerDay = 86400;
        uint totalSecondsOfAuctionRun = _noOfDaysTorun.mul(secondsPerDay);
        uint totalBlocksOfAuctionRun = totalSecondsOfAuctionRun.div(15);
        
        startBlock = block.number;
        endBlock = startBlock.add(totalBlocksOfAuctionRun);
        bidIncrement = 1000000000000000000;
    }
    
    modifier notOwner() {
        require(msg.sender != owner,"Owner cant place bid");
        _;
    }
    
    modifier afterStart() {
        require(block.number >= startBlock,"StartBlock is greater than the current block number");
        _;
    }
    
    modifier beforeEnd() {
        require(block.number <= endBlock,"EndBlock is less than the block number");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner,"Only owner can cancel the Auction");
        _;
    }
    
    modifier isCancelledOrEnded() {
        require(actionState == State.Cancelled || block.number > endBlock,"Aucton is not Cancelled");
        _;
    }
    
    function min(uint value1, uint value2) internal pure  returns(uint) {
        if(value1 <= value2){
            return value1;
        }else {
            return value2;
        }        
    }
    
    /**
        @dev - Cancel auction
     */
    function cancelAuction() public onlyOwner {
        actionState = State.Cancelled;    
    }
    
    /**
        @dev bidding process
     */
    function placeBid() public  payable notOwner afterStart beforeEnd returns(bool) {
        require(actionState == State.Running, "Auction is either cancelled or ended");
        require(msg.value > 0.001 ether,"Required amount to place a bid should be greater than 0.001 ether");
        
        uint currentBid = bids[msg.sender] + msg.value;
        
        require(currentBid > highestBindingBid,"current bid is less than the highest binding bid");
        bids[msg.sender] = currentBid;        
        
        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else 
        {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = msg.sender;
        }
        return true;
        
    }
    
    
    /**
        @dev bidding reach the number of days running or the owner cancel it
     */
    function endedAuction() public payable isCancelledOrEnded {
        require(msg.sender == owner || bids[msg.sender] > 0, "Your are not the owner or you dont bid");
        
        //cancelled state...return ether to the bidders
        if(actionState == State.Cancelled) {
            msg.sender.transfer(bids[msg.sender]);
        }
        else
        {
            
            if(msg.sender == owner){ //scenario #1 : Auction ended and its the owner
                msg.sender.transfer(highestBindingBid);        
            }
            else if (highestBidder == msg.sender) {//scenario #2 : Auction ended and its not the owner but the winner
                msg.sender.transfer(bids[highestBidder] - highestBindingBid);
            }
            else {//scenario #3 : Auction ended and its not the owner and not the winner
                msg.sender.transfer(bids[msg.sender]);
            }
        }
        
    }
}
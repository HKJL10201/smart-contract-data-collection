pragma solidity ^0.5.8;

contract ChocoAuction{
    address payable public beneficiary;
    address public highestBidder;
    uint public highestBid;
    uint Fri_Nov_01_00_00_UTC_2019 = 1572566400;
    uint endAuctionDay;
    bool open = true;

    mapping(address => uint) pendingReturns;

    modifier isOpen(){
        require(open == true,
        "Is too late to make a bid. The auction has ended"
        );
        _;
    }

    modifier isHigh(){
        require(msg.value + pendingReturns[msg.sender] > highestBid,
        "The amount is not enough to overcome the previous bid"
        );
        _;
    }

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor() public payable {
        beneficiary = msg.sender;
        // Señala la fecha de culminacion de la subasta.
        endAuctionDay = Fri_Nov_01_00_00_UTC_2019;
    }

    function bid() public payable isOpen isHigh returns(bool){
        closeIt();
        require(msg.sender != highestBidder,
        "HighestBidder cannot make rebidding"
        );
        require(pendingReturns[msg.sender] == 0,
        "You have a pending found, make rebidding");
        pendingReturns[highestBidder] = highestBid;
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit HighestBidIncreased(highestBidder, highestBid);
        return true;
    }

    function rebid() public payable isOpen isHigh returns(bool){
        closeIt();
        require(msg.sender != highestBidder,
        "HighestBidder cannot make rebidding"
        );
        require(pendingReturns[msg.sender] > 0,
        "This function only work if you have a overcame bid"
        );
        pendingReturns[highestBidder] = highestBid;
        highestBid = msg.value + pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;
        highestBidder = msg.sender;
        emit HighestBidIncreased(highestBidder, highestBid);
        return true;
    }

    function auctionEnd() public returns(bool){
        require(msg.sender == beneficiary,
        "Only beneficiary can call this function"
        );
        require(block.timestamp > endAuctionDay,
        "Auction isn't ended yet"
        );
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
        closeIt();
        return true;
    }

    function myPendingFunds() public view returns (uint){
        return pendingReturns[msg.sender];
    }

    function closeIt() internal returns (bool) {
        if (endAuctionDay < block.timestamp) {
            open = false;
            return open;
        }
    }

    function isClosed () public view returns(bool) {
        return !open;
    }

    function withdrawPendings() public returns(uint){
        require(pendingReturns[msg.sender] > 0,
        "You don't have any funds on this contract"
        );
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return 0;
            }
        }
        return amount;
    }
}
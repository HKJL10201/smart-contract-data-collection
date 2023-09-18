//For unix time stamp, go to: https://www.unixtimestamp.com/
pragma solidity >=0.5 <0.9;

contract Auction{
    address private owner;
    address public highestBidder;
    bool private ownerHasWithdrawn;
    bool private cancelled;
    uint public startDate;
    uint public endDate;
    uint public bidIncrement;
    uint public highestBindingBid;
    mapping(address => uint) private bids;


    constructor(uint _startDate, uint _endDate, uint _bidIncrement){
        require(_startDate < _endDate, "Start date should be before end date.");
        owner = msg.sender;
        startDate = _startDate;
        endDate = _endDate;
        bidIncrement = _bidIncrement;
    }
    
    function min(uint a, uint b) private view returns (uint) {
        if (a < b) return a;
        return b;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }


    function placeBids() public payable auctionIsNotExpired auctionHasStarted notCancelled notOwner returns (bool) {
        require(msg.value > 0, "Value needs to be greater than 0 eth.");
        uint newBid = bids[msg.sender] + msg.value;
        require(newBid > highestBindingBid, "New bid not greater than highest binding bid."); //rejects any bids < highest binding bid
        uint highestBid = bids[highestBidder];
        bids[msg.sender] = newBid;
        if (newBid <= highestBid) {
            highestBindingBid = min(newBid + bidIncrement, highestBid);
        } else {
            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + bidIncrement);
            }
            highestBid = newBid;
        }

        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;

    }

    function withdraw() public auctionEndedOrCancelled returns (bool) { 
        address payable withdrawalAccount;
        uint withdrawalAmount;

        if (cancelled) {
            withdrawalAccount =  payable(msg.sender);
            withdrawalAmount = bids[withdrawalAccount];
        } else {
            if (msg.sender == owner) {
                withdrawalAccount = payable(highestBidder);
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;
            } else if (msg.sender == highestBidder) {
                withdrawalAccount = payable(highestBidder);
                if (ownerHasWithdrawn) {
                    withdrawalAmount = bids[highestBidder];
                } else {
                    withdrawalAmount = bids[highestBidder] - highestBindingBid;
                }
            } else {
                withdrawalAccount = payable(msg.sender);
                withdrawalAmount = bids[withdrawalAccount];
            }
        }

        require(withdrawalAmount >= 0, "Withdraw amount should be >= 0.");
        bids[withdrawalAccount] -= withdrawalAmount;
        require(payable(msg.sender).send(withdrawalAmount) == true, "Could not send.");
        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        return true;

    }

    function cancelAuction() public onlyOwner notAlreadyCancelled auctionIsNotExpired {
        cancelled = true;
        emit LogCancelled();
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not allowed to perform this action.");
        _;
    }

    modifier notAlreadyCancelled(){
        require(cancelled == false, "This auction has been already cancelled.");
        _;
    }

    modifier notCancelled(){
        require(cancelled == false, "This auction has been cancelled.");
        _;
    }

    modifier auctionIsNotExpired(){
        require(block.timestamp < endDate, "This auction has expired.");
        _;
    }

    modifier auctionHasStarted(){
        require(block.timestamp > startDate, "This auction has not started.");
        _;
    }

    modifier auctionEndedOrCancelled {
        require(block.timestamp > endDate || cancelled, "Auction is still live.");
        _;
    }

    modifier notOwner {
        require(msg.sender != owner, "Owner cannot bid.");
        _;
    }

    event LogCancelled();
    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid); 
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
}
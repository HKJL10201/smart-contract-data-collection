pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {


    address payable public beneficiary;

    uint public auctionEndTime;

    address public highestBidder;

    uint public highestBid;


    mapping(address => uint) pendingReturns;

    bool ended;
    

    uint public minIncrement; 
    uint public minRequiredStartBid; 
    
    uint private luckyNumber;
    
    uint public autoPayToBeneficiaryPeriod;
    

    event HighestBidIncreased(address bidder, uint amount);
    

    event AuctionEnded(address winner, uint amount);


    constructor(
        
        uint _biddingTime,
        address payable _beneficiary,
        uint _minIncrement, // Q2B(a)
        uint _minRequiredStartBid, // Q2B(a)
        uint _luckyNumber
 
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + (_biddingTime * 1 seconds) ;
        minIncrement = _minIncrement; // Q2B(a)
        minRequiredStartBid = _minRequiredStartBid; // Q2B(a)
        luckyNumber = _luckyNumber;
    }

    
    function bid() public payable {
        
    
        if (highestBid == 0) {
            require(
                msg.value >= minRequiredStartBid,
                "Minimal required start bid is not met."
            );
        }
        
 
        require(
            minIncrement <= msg.value - highestBid,
            "Minimal increment for each bid is not met"
        );

        require(
            now <= auctionEndTime,
            "Auction already ended."
        );

        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );
        
        require(
            !ended,
            "Auction has ended. Lucky Winner appeared!"
        );
        
        if (highestBid != 0) {
            
            pendingReturns[highestBidder] += highestBid;
        }
        
    
        
        if (msg.value == (highestBid + luckyNumber + minIncrement)) {
             auctionEnd();
             
        } 
        
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
        
    }


    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];A
        if (amount > 0) {

            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
 
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    

    function auctionEnd() private {

        //require(msg.sender == contract_owner, "Only the contract owner can end an auction.");
        //require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

 
        ended = true;
        autoPayToBeneficiaryPeriod = auctionEndTime * (2 * 1 seconds);
        emit AuctionEnded(highestBidder, highestBid);
        
        //beneficiary.transfer(highestBid);
    }
    
    function highestBidderOK() public {
        require(
            ended, "The auction has not ended yet."    
        );
        require(
            (msg.sender ==  highestBidder) || (now >= autoPayToBeneficiaryPeriod) ,
            "Only the auction winner is allowed to release the funds or you have to wait until the autoPayToBeneficiaryPeriod is reached."
        );
        
        
        beneficiary.transfer(highestBid);
    }
}

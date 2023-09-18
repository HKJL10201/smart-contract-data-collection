pragma solidity >=0.7.0 <0.8.0;

contract auction {
    address payable private auctionManager;
    uint private startTime;
    
    // used to allow the use of activateWinner function once
    bool private activateWinnerBool;
    
    uint private counter; 
    
    // mapping between bidders address and their hashed bid 
    mapping (address => bytes32) private bids;

    
    address payable private winner;
    uint256 private winner_bid;
    // 2nd highest value / value that the bidder actually pays
    uint256 private winner_actual;
    
    // bidding and revealing time frames in seconds, currenlty set to 3 days, unused currently for TESTING purposes
    uint256 private biddingTimeFrame = 259200;
    uint256 private revealingTimeFrame = 259200 ;
    
    //value payed in deposit by auctionManager to construct the contract & the bidders to bid, currently set as 1 ether 
    uint private depositFees = 1000000000000000000 ;
    
    
    modifier PayDeposit {
        require(msg.value == depositFees);
            _;
    }
    
    // constuct contract
    constructor () payable PayDeposit {
        auctionManager = msg.sender ;
        counter = 0;
        startTime = block.timestamp;
        activateWinnerBool = true;
    }   
    
    // bidder will send the hash of (public address(to prevent smth similar to a reply attack), value and nonce ) and Pay Deposit fees
    function commit(bytes32 input) payable PayDeposit public{
        
        // bidding is available  for biddingTimeFrame,commented for TESTING
        //require(block.timestamp < startTime + biddingTimeFrame);       
        
        bids[msg.sender] = input;
    }
    
    function reveal(uint256 value,bytes32 nonce) payable public {
        
        // revealing is available for revealingTimeFrame, commented for TESTING
        //require( block.timestamp > startTime + biddingTimeFrame  && block.timestamp < startTime + biddingTimeFrame + revealingTimeFrame);       
        
        // bidder should reveal the value and nonce used to generate hash value in the biddingTimeFrame
        require( sha256(abi.encodePacked(msg.sender,value,nonce)) == bids[msg.sender], "Mismatch between values submitted and stored hash" );
        
        // bidder should pay the value aggreed upon in the biddingTimeFrame - the depositFees paid in bid transaction 
        require( msg.value == value - depositFees, "ether sent in the transaction doesnt match value specified in the inital bidding" );
        
        // update winner
        
        // if its the first reveal then he is currently the winner
        if (counter == 0){
            winner = msg.sender;
            winner_bid = value;
            winner_actual = value;
            counter ++;
        }
        
        // if its the 2nd reveal, either be higher and update the winner 
        else if (counter == 1){
            if (value > winner_bid){
                
                // reutrn money to old bidder
                winner.transfer(winner_bid);
                
                // update winner
                winner = msg.sender;
                winner_actual = winner_bid;
                winner_bid = value;
            }
            
            // or be the loser and just update the 2nd hight value (value that the winner actually pays)
            else{
                winner_actual = value;
                msg.sender.transfer(value);
            }
            
            counter ++;
        }
        
        // after the 1st and 2nd reveal the algorithm continues normally
        // he wins 
        else if (value > winner_bid){
            
            // reutrn money to old bidder
            winner.transfer(winner_bid);
            
            // update winner
            winner = msg.sender;
            winner_actual = winner_bid;
            winner_bid = value;
        }
        
        // he loses but updates the 2nd highest value
        else if (value > winner_actual){
            
            //update
            winner_actual = value;
            msg.sender.transfer(value);
        }
        
        // he lost and doesnt update the 2nd highest value
        else {
            msg.sender.transfer(value);
        }
    }
    
    function activateWinner() public returns (address){
        
        // activateWinner after bidding and revealingTimeFrame,commented for TESTING
        //require(block.timestamp > startTime + biddingTimeFrame + revealingTimeFrame);       

        // can only be activated once 
        require (activateWinnerBool == true, "activateWinner can only be called once");
        activateWinnerBool = false;
        
        winner.transfer(winner_bid - winner_actual);
        auctionManager.transfer(winner_actual);
        
        // return ether stuck in contract to auctionManager
        auctionManager.transfer(address(this).balance);
        
        return (winner);
        
        // TODO winning logic
    }
    
    // used for testing
    function checkWinner() public view returns (address){
        return(winner);
    }
    
    // used for testing
    function generateInput(uint256 value,bytes32 nonce) public view returns (bytes32){
        return sha256(abi.encodePacked(msg.sender,value,nonce));
    }
    
}

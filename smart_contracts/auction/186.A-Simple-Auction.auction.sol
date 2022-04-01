
pragma solidity ^0.7.0;

contract Purchase {
    uint256 public minimumDepositValueInWei; // can also be considered as the starting value for bidding
    uint public endBiddingTime;
    uint public endRevealingTime;
    uint public endFinalizationTime;
    
    uint256 public secondHighestRevealedBid;
    uint256 public highestRevealedBid;
    address payable public highestRevealedBidder;
    
    address payable public auctionManager; 
    uint256 public auctionManagerDeposit;

    mapping (address=>uint256) public BiddersToDeposits;
    mapping (address=>bytes32) public BiddersToHashedBids;
    mapping (address=>uint256) public BiddersToRevealedBids;
    
    address payable[] public honestBidders;
    uint honestBiddersCount = 0;

    enum AuctionState {Created, InAction, Ended}
    AuctionState public auctionState;
    
    modifier auctionInState(AuctionState _auctionState) {
        require(auctionState == _auctionState, "Invalid state." );
        _;
    }
    
    modifier auctionNotInState(AuctionState _auctionState) {
        require(auctionState != _auctionState, "Invalid state." );
        _;
    }

    modifier calledByAuctionManager() {
        require(msg.sender == auctionManager, "Only auction manager can call this.");
        _;
    }
    
    modifier notCalledByAuctionManager() {
        require( msg.sender != auctionManager, "Auction manager can not call this.");
        _;
    }
    
    modifier calledByHonestParticipant(){
        bool isHonestBidder = false;
        for (uint i = 0; i < honestBiddersCount; i++){
            if (honestBidders[i] == msg.sender){
                isHonestBidder = true;
                break;
            }
        }
        require(isHonestBidder == true, "Only honest participant bidders can call this.");
        _;
    }
    
    modifier calledByWinner(){ // called by HighestRevealedBidder
        require( msg.sender == highestRevealedBidder, "Only winner can call this.");
        _;
    }
    
    modifier notCalledByWinner(){ // not called by HighestRevealedBidder
        require( msg.sender != highestRevealedBidder, "Winner can not call this.");
        _;
    }
    
    modifier checkWinnerTxValue(){ // checks that the winner tx alue is equal to revealedBid - deposit
        require (BiddersToDeposits[msg.sender] != 0, "Winner has already sent bid money to manager");
        
        if(secondHighestRevealedBid == 0){
            require(msg.value == 0, "second highest bidding is zero, winner must only pay the deposit value.");
        }
        else {
            require( msg.value == secondHighestRevealedBid - BiddersToDeposits[msg.sender], "Winner tx value is not equal to second highest revealed bid - deposit.");
        }
        _;
    }
    
    modifier inBiddingTime(uint256 time){
        require(time < endBiddingTime, "Bidding time has ended.");
        _;
    }
    
    modifier inRevealingTime(uint256 time){
        require(time < endRevealingTime, "Revealing time has ended.");
        require(time >= endBiddingTime, "Revealing time hasn't started yet.");
        _;
    }
    
    modifier inFinalizationTime(uint256 time){
        require(time < endFinalizationTime, "Finalization time has ended.");
        require(time >= endRevealingTime, "Finalization time hasn't started yet.");
        _;
    }
    
    modifier afterFinalizationTime(uint256 time){
        require(time >= endFinalizationTime, "After Finalization time hasn't started yet.");
        _;
    }

    modifier valueExceedMinimumDeposit(){
       require (msg.value >= minimumDepositValueInWei, "Deposit value is less than allowed.");
        _;
    }
    
    modifier bidderPlacedDeposit() {
        require(BiddersToDeposits[msg.sender] != 0, "Deposit has not been placed.");
        _;
    }
    
    modifier bidderPlacedHashedBid() {
        require(BiddersToHashedBids[msg.sender] != 0x0, "Hashed bid has not been placed.");
        _;
    }
    
    modifier bidderRevealedBid(){
        require(BiddersToRevealedBids[msg.sender] != 0, "Revealed bid has not been placed.");
        _;
    }
    
    modifier bidderDidNotBidBefore(){
        require(BiddersToDeposits[msg.sender] == 0 && BiddersToHashedBids[msg.sender] == 0, "Bidder can only place a bid once.");
        _;
    }
    
    modifier bidderDidNotRevealBefore(){
        require(BiddersToRevealedBids[msg.sender] == 0, "Bidder can only reveal a bid once.");
        _;
    }
    
    modifier bidderDidNotRefundBefore(){
        require(BiddersToDeposits[msg.sender] != 0, "Bidder can refund his deposit only once.");
        _;
    }
    
    modifier verifyRevealedBidEqualHashedBid(uint256 random, uint256 revealedBid) {
        require(BiddersToHashedBids[msg.sender] == keccak256(abi.encode(msg.sender, random, revealedBid)), "hashed bid not equal.");
        _;
    }
    
    modifier verifyRevealedBidBiggerThanDeposit(uint256 revealedBid) {
        require(BiddersToDeposits[msg.sender] < revealedBid, "Revealed bid must be bigger than deposited value.");
        _;
    }

    constructor(uint256 _minimumDepositValueInWei, uint256 biddingDurationInMinutes, uint256 revealingDurationInMinutes, uint256 finalizationDurationInMinutes)
    payable 
    {
        auctionManager = msg.sender;
        // the auction manager will also place a deposit as an incentive to complete the protocol and not dissappear in the middle of the process
        minimumDepositValueInWei = _minimumDepositValueInWei * 1 wei;
        require (msg.value >= minimumDepositValueInWei, "Deposit value is less than allowed.");
        auctionManagerDeposit = msg.value;
        auctionState = AuctionState.Created;
        endBiddingTime = block.timestamp + biddingDurationInMinutes * 1 minutes;
        endRevealingTime = endBiddingTime + revealingDurationInMinutes * 1 minutes;
        endFinalizationTime = endRevealingTime + finalizationDurationInMinutes * 1 minutes;
        highestRevealedBid = 0;
        secondHighestRevealedBid = 0;
    }
    
    // Can only be called by the auction manager.
    // Abort the auction and reclaim the deposit made by the auction maager ONLY IF the current state of the auction is created i.e. no bidder has placed a bid yet.
    function abort()
        public
        auctionInState(AuctionState.Created)
        calledByAuctionManager()
    {
        auctionState = AuctionState.Ended;
        auctionManager.transfer(address(this).balance);
    }

    function placeDepositsAndBids(bytes32 hashedBid)
        public
        inBiddingTime(block.timestamp)
        auctionNotInState(AuctionState.Ended) // state can be created or in action
        notCalledByAuctionManager()
        valueExceedMinimumDeposit()
        bidderDidNotBidBefore()
        payable
    {
        // place deposit
        BiddersToDeposits[msg.sender] = msg.value;
        auctionState = AuctionState.InAction; // at least on deposit is placed, state is inAction so that manager can not abort
        // place hashed bid
        BiddersToHashedBids[msg.sender] = hashedBid;
        
    }
    
    function reveal(uint256 random, uint256 revealedBid)
        public
        inRevealingTime(block.timestamp)
        auctionInState(AuctionState.InAction)
        notCalledByAuctionManager()
        bidderDidNotRevealBefore()
        bidderPlacedHashedBid()
        verifyRevealedBidEqualHashedBid(random, revealedBid)
        verifyRevealedBidBiggerThanDeposit(revealedBid)
    {
        
        BiddersToRevealedBids[msg.sender] = revealedBid;
        honestBidders.push(msg.sender);
        honestBiddersCount++;
        
        if(highestRevealedBid < revealedBid){ // what if 2 has the same highest bid??
            secondHighestRevealedBid = highestRevealedBid;
            highestRevealedBid = revealedBid;
            highestRevealedBidder = msg.sender;
        }
        else if(secondHighestRevealedBid == 0 && honestBiddersCount>=2){
            secondHighestRevealedBid = revealedBid;
        }
    }
    
    function refundDeposit()
        public
        inFinalizationTime(block.timestamp)
        // auctionInState(AuctionState.InAction) Dont need to check state as the only condition to refund a deposit is that it is in Finalization time and the refunder is not the highest bidder nor the auction manager nor a cheater, those checks are checked below
        notCalledByAuctionManager()
        notCalledByWinner()
        // bidder can only refund his deposit once
        bidderDidNotRefundBefore()
        // make sure he followed all the rules and the auction protocole to get the refund i.e. not a cheater
        bidderPlacedDeposit()
        bidderPlacedHashedBid()
        bidderRevealedBid()
        payable
    {
        // return deposits to bidders
        msg.sender.transfer(BiddersToDeposits[msg.sender]);
        BiddersToDeposits[msg.sender] = 0;
    }
    
    // winner send [ highestRevealedBid - his deposit ] to manager
    function winnerSendMoneyToManager()
        public 
        inFinalizationTime(block.timestamp)
        // auctionInState(AuctionState.InAction) Dont need to check state as the only condition to refund a deposit is that it is in Finalization time 
        calledByWinner()
        checkWinnerTxValue()
        payable
    {
        auctionManager.transfer(msg.value + BiddersToDeposits[msg.sender]);
        // winner's deposit now is equal to zero as he transferred his money to manager.
        BiddersToDeposits[msg.sender] = 0;
    }
    
    // called by manager after the winner called the "winner send money to manager" function to send the transaction with the send bid to the contract
    function endAuctionByManager()
        public
        inFinalizationTime(block.timestamp)
        calledByAuctionManager()
        auctionNotInState(AuctionState.Ended)
    {
        // the manager refund his deposit
        auctionManager.transfer(auctionManagerDeposit);
        // manager's deposit now is equal to zero as he refunded his money.
        auctionManagerDeposit = 0;   

        uint totalBalance = address(this).balance;
        uint share = totalBalance / (honestBiddersCount-1 +1); // integer divsion // +1 is for manager // -1 for winner as he deposit was laready sent to the manager
        uint sum = 0;
        for (uint i = 0; i < honestBidders.length; i++){
            if(honestBidders[i] == highestRevealedBidder){
                continue;
            }
            honestBidders[i].transfer(share);
            sum += share;
        }
        sum += share; // manager share
        
        //  the manager gets his share + rest of integer division  
        auctionManager.transfer(share + (totalBalance - sum));
        
        // end auction
        auctionState = AuctionState.Ended;
    }
    
    function endAuctionByParticipant()
        public
        afterFinalizationTime(block.timestamp)
        notCalledByAuctionManager()
        notCalledByWinner()
        calledByHonestParticipant()
        auctionNotInState(AuctionState.Ended)
    {
        
        uint totalBalance = address(this).balance;
        uint share = totalBalance / (honestBiddersCount-1); // integer divsion  // -1 for winner
        uint sum = 0;
        for (uint i = 0; i < honestBidders.length; i++){
            if(honestBidders[i] == highestRevealedBidder){
                continue;
            }
            honestBidders[i].transfer(share);
            sum += share;
        }
        
        // the caller get the rest of integer division  
        msg.sender.transfer(totalBalance - sum);
        
        // end auction
        auctionState = AuctionState.Ended;
    }
}

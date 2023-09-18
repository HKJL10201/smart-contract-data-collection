pragma solidity ^0.4.11;

contract EttaDice {

    struct GameRound {
        uint roundId;
        address player;
        uint stake;
        string bets;
        string gameResult;        
        uint winLoss;
        uint payOut;
        bool isSettled; 
    }

    /*
     * Game stakeholder
    */
    address public owner;
    address public operator;

    /*
     * Game vars
    */
    bool public isActive = true;
    uint public minBet = 10 finney;
    uint public maxBet = 3500 finney;
    uint public totalPendingPayout = 0;
    uint8 public maxPayoutPercentage = 70;

    /*
     * Player bets
    */
    mapping(address=>mapping(uint => GameRound)) public playerBets;

    /*
     * Events
    */    
    event onBetPlaced(uint indexed roundId, address indexed player, uint betOption, string orderDetail, uint stake);
    event onBetSettled(uint indexed roundId, address indexed player, uint returnToPlayer);
    event onBetRefunded(uint indexed roundId, address indexed player, uint amount);
    event onTransferFailed(address receiver, uint amount);

    /*
     * Constructor
    */ 
    function EttaDice(uint minBetInitial, uint maxBetInitial, address operatorInitial) payable {
        if (minBetInitial != 0) {
            minBet = minBetInitial;
        }
        if (maxBetInitial != 0) {
            maxBet = maxBetInitial;
        }
        if (operatorInitial != 0) {
            operator = operatorInitial;
        } else {
            operator = msg.sender;
        }
        owner = msg.sender;
    }

    /*
     * Modifier for ensuring that only the owner can access.
    */   
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*
     * Modifier for ensuring that only operators can access.
    */
    modifier onlyOperator{
        require(msg.sender == operator);
        _;       
    }

    /*
     * Modifier for ensuring that this function is only called when player wins the bet.
    */    
    modifier onlyWinningBet(uint winloss) {
        if (winloss > 0) {
            _;
        }
    }

    /*
     * Modifier for ensuring that this function is only called when player loses the bet.
    */
    modifier onlyLosingBet(uint winloss) {
        if (winloss <= 0) {
            _;
        }
    }

    /*
     * Modifier for checking that the game is active.
    */    
    modifier onlyIfActive {
        require(isActive);
        _;
    }

    /*
     * Modifier for checking that the game is inactive.
    */
    modifier onlyIfInactive {
        require(!isActive);
        _;
    }

    /*
     * Modifier for checking that the round ID doesn't repeat.
    */     
    modifier onlyNewRoundId(uint roundId) {
        if (playerBets[msg.sender][roundId].roundId != 0) {
            revert();
        }
        _;
    }

    /*
     * Modifier for checking that the bet is not settled.
    */  
    modifier onlyNotSettled(address player, uint roundId) {
        if (playerBets[player][roundId].roundId == 0 || playerBets[player][roundId].isSettled == true) {
            revert();
        }
        _;
    }  

    event onAffordable(uint balance, uint percentage, uint totalPendingPayoutValue, uint payout, int r1);

    /*
     * Modifier for checking that the stake is less than maximum bet.
    */ 
    modifier onlySmallerThanMaxBet {
        if (msg.value > maxBet) {
            revert();
        }
        _;
    }

    /*
     * Modifier for checking that the stake is greater than minimum bet.
    */    
    modifier onlyGreaterThanMinBet {
        if (msg.value < minBet) {
            revert();
        }
        _;
    }

    /*
     * Modifier for ensuring that the total payout is still affordable for owner.
    */      
    modifier onlyPendingPayoutAffordable(uint payOut) {
        uint processedStakeTimesPercentage = this.balance * maxPayoutPercentage / 100;
        uint tPendingPayout = totalPendingPayout;
        int r1 = int(processedStakeTimesPercentage - tPendingPayout - payOut);
        if ( r1 <= 0 ) {
            revert();
        }
        _;
    }

     /*
     * Public function
     * Betting.
     * Execute when:
     *  - Game is set to active.
     *  - Stake is between minimum bet and maximum bet.
     *  - The total pending payout is affordable for owner.
     *  - Round ID doesn't exist.
    */   
    function bet(uint8 betOption, string orderDetail, uint roundId, uint payOut) payable onlyIfActive onlyGreaterThanMinBet onlySmallerThanMaxBet onlyPendingPayoutAffordable(payOut) onlyNewRoundId(roundId) {
        var  gameRound = GameRound(roundId, msg.sender, msg.value, orderDetail, "", 0, payOut, false);
        playerBets[msg.sender][roundId] = gameRound;
        onBetPlaced(roundId, msg.sender, betOption, orderDetail, msg.value);
        totalPendingPayout += payOut;
    }

    /*
     * Public function
     * For operator to settle the bet.
     * Only operators are authorized to call this function.
     * Execute when the bet has not settled yet.
    */      
    function settle(address player, uint roundId, uint winLoss, string gameResult, uint returnToPlayer) public onlyOperator onlyNotSettled(player, roundId) returns(bool) {
        GameRound storage gameRound = playerBets[player][roundId];
        gameRound.gameResult = gameResult;
        gameRound.winLoss = winLoss + returnToPlayer;

        settleWinningBet(player, gameRound.winLoss);
        settleLosingBet(player, gameRound.winLoss);
        gameRound.isSettled = true;
        totalPendingPayout -= gameRound.payOut;
        onBetSettled(roundId, player, returnToPlayer);
        return true;
    }

    /*
     * Public function
     * For operator to refund the bet.
     * Only operators are authorized to call this function.
     * Execute when the bet has not settled yet.
    */      
    function refund(address player, uint roundId, uint amount) public onlyOperator onlyNotSettled(player, roundId) returns(bool) {
        GameRound storage gameRound = playerBets[player][roundId];
        gameRound.gameResult = "";
        gameRound.winLoss = amount;

        settleWinningBet(player, amount);
        gameRound.isSettled = true;
        totalPendingPayout -= gameRound.payOut;
        onBetRefunded(roundId, player, amount);
        return true;
    }

    /*
     * Private function 
     * For operator to settle the bet.
     * Only operators are authorized to call this function.
     * Execute when the bet is a winning bet.
    */       
    function settleWinningBet(address player, uint winloss) private onlyOperator onlyWinningBet(winloss) {
        player.transfer(winloss);
    }

    /*
     * Private function 
     * For operator to settle the bet.
     * Settle the losing bet and transfer 1 Wei back to player.
     * Execute when the bet is a losing bet.
    */       
    function settleLosingBet(address player, uint winloss) private onlyOperator onlyLosingBet(winloss) {
        player.transfer(1);
    }

    /*
     * Public function 
     * Activate the game.
     * Only operators are authorized to call this function.
    */      
    function setGameActive() public onlyOperator {
        isActive = true;
    }

    /*
     * Public function 
     * Deactivate the game.
     * Only operators are authorized to call this function.
    */        
    function setGameStopped() public onlyOperator {
        isActive = false;
    }	

    /*
     * Public function 
     * Set the affordable payout.
     * Only operators are authorized to call this function.
    */ 
    function setMaxPayoutPercentage(uint8 percentage) public onlyOperator {
        maxPayoutPercentage = percentage;
    }

    /*
     * Public function 
     * Update globally the minimum bet to new value.
     * Only operators are authorized to call this function.
    */       
    function setMinBet(uint newMinBet) public onlyOperator {
        minBet = newMinBet;
    }

    /*
     * Public function 
     * Update globally the maximum bet to new value.
     * Only operators are authorized to call this function.
    */       
    function setMaxBet(uint newMaxBet) public onlyOperator {
        maxBet = newMaxBet;
    }

    /*
     * Public function 
     * Globally update operator
     * Only owner is authorized to call this function.
    */       
    function setOperator(address newOperator) public onlyOwner {
        operator = newOperator;
    }

     /*
     * Public function 
     * Transfer the balance of contract to owner's address.
     * Only owner is authorized to call this function.
    */      
    function transferToOwner(uint amount) public onlyOwner {
        if(int(this.balance - amount - totalPendingPayout) <= 0) {
            onTransferFailed(owner, amount);
            return;
        }
        owner.transfer(amount);
    }

    /*
     * Public function 
     * Destroy the contract.
     * Only owner is authorized to call this function.
    */     
    function ownerkill() public onlyOwner {
		selfdestruct(owner);
	}

    /*
     * Public function 
     * Activate the game.
     * Only operators are authorized to call this function.
    */      
    function setTotalPendingPayout(uint value) public onlyOperator {
        totalPendingPayout = value;
    }     

    /*
     * Public function
     * Only owner can transfer Ether to the contract.
    */    
    function () payable onlyOwner {
        
    }

}
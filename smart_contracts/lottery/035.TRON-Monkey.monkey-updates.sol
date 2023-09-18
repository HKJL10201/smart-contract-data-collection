/*  TRON VERSION JANUARY 2019
 ____   _______  _______  _______  __   __    __   __  _______  __    _  ___   _  _______  __   __
|    | |  _    ||  _    ||       ||  | |  |  |  |_|  ||       ||  |  | ||   | | ||       ||  | |  |
 |   | | | |   || | |   ||_     _||  |_|  |  |       ||   _   ||   |_| ||   |_| ||    ___||  |_|  |
 |   | | | |   || | |   |  |   |  |       |  |       ||  | |  ||       ||      _||   |___ |       |
 |   | | |_|   || |_|   |  |   |  |       |  |       ||  |_|  ||  _    ||     |_ |    ___||_     _|
 |   | |       ||       |  |   |  |   _   |  | ||_|| ||       || | |   ||    _  ||   |___   |   |
 |___| |_______||_______|  |___|  |__| |__|  |_|   |_||_______||_|  |__||___| |_||_______|  |___|

*/

pragma solidity ^0.4.25;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "the SafeMath multiplication check failed");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "the SafeMath division check failed");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "the SafeMath subtraction check failed");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "the SafeMath addition check failed");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "the SafeMath modulo check failed");
        return a % b;
    }
}

contract OneHundredthMonkey {

    using SafeMath for uint256;

    ///////////
    //STORAGE//
    ///////////

    //ADMIN
    uint256 public adminBalance;
    address public adminBank;
    address[] public admins;
    mapping (address => bool) public isAdmin;

    //GLOBAL
    bool public gameActive = false;
    bool public earlyResolveACalled = false;
    bool public earlyResolveBCalled = false;
    uint256 public activationTime = now; // (GMT): Saturday, March 9, 2019 5:00:00 PM
    uint256 public roundsPerCycle = 100;
    uint256 public roundPotRate = 30; //30%
    uint256 public progressivePotRate = 30; //30%
    uint256 public roundRewardRate = 30; //30%
    uint256 public roundAirdropRate = 9; //9%
    uint256 public adminFeeRate = 1; //1%
    uint256 public cyclePotRate = 100; //100% of progressive pot
    uint256 internal precisionFactor = 18;
    uint256 public seedAreward = 25000000000000000;
    uint256 public seedBreward = 25000000000000000;
    mapping (uint256 => bool) public roundSeedAawarded;
    mapping (uint256 => bool) public roundSeedBawarded;

    //RNG
    uint256 internal RNGblockDelay = 1;
    uint256 internal salt = 0;
    bytes32 internal hashA;
    bytes32 internal hashB;

    //ROUND TRACKING
    bool public roundProcessing;
    uint256 public roundCount;
    uint256 public roundProcessingBegun;
    mapping (uint256 => bool) public roundPrizeClaimed;
    mapping (uint256 => bool) public roundAirdropClaimed;
    mapping (uint256 => uint256) public roundStartTime;
    mapping (uint256 => uint256) public roundEndTime;
    mapping (uint256 => uint256) public roundTokens;
    mapping (uint256 => uint256) public roundTokensLeft;
    mapping (uint256 => uint256) public roundTokensActive;
    mapping (uint256 => uint256) public roundTokenRangeMin;
    mapping (uint256 => uint256) public roundTokenRangeMax;
    mapping (uint256 => uint256) public roundPrizeNumber;
    mapping (uint256 => uint256) public roundAirdropNumber;
    mapping (uint256 => uint256) public roundPrizePot;
    mapping (uint256 => uint256) public roundAirdropPot;
    mapping (uint256 => uint256) public roundRewards;
    mapping (uint256 => uint256) public roundRewardsClaimed;
    mapping (uint256 => address) public roundPrizeWinner;
    mapping (uint256 => address) public roundAirdropWinner;

    //CYCLE TRACKING
    bool public cycleOver = false;
    bool public cyclePrizeClaimed;
    bool public cyclePrizeTokenRangeIdentified;
    uint256 public totalVolume;
    uint256 public totalBuys;
    uint256 public tokenSupply;
    uint256 public cycleActiveTokens;
    uint256 public cycleCount;
    uint256 public cycleEnded;
    uint256 public cycleProgressivePot;
    uint256 public cyclePrizeWinningNumber;
    uint256 public cyclePrizeInRound;
    uint256 public cycleStartTime;
    address public cyclePrizeWinner;

    //TOKEN TRACKING
    uint256 public tokenPrice = 100 tron;
    uint256 public tokenPriceIncrement = 5 tron;
    uint256 public minTokensPerRound = 2000; //between 1x and 2x this amount of tokens generated each minigame

    //USER TRACKING PUBLIC
    address[] public uniqueAddress;
    mapping (address => bool) public knownUsers;
    mapping (address => uint256) public userTokens;
    mapping (address => uint256) public userBalance;
    mapping (address => mapping (uint256 => uint256)) public userRoundTokens;
    mapping (address => mapping (uint256 => uint256[])) public userRoundTokensMin;
    mapping (address => mapping (uint256 => uint256[])) public userRoundTokensMax;

    //USER TRACKING INTERNAL
    mapping (address => bool) public userCycleChecked;
    mapping (address => uint256) public userLastRoundInteractedWith;
    mapping (address => uint256) public userLastRoundChecked;
    mapping (address => mapping (uint256 => uint256)) public userShareRound;
    mapping (address => mapping (uint256 => uint256)) public userRewardsRoundTotal;
    mapping (address => mapping (uint256 => uint256)) public userRewardsRoundClaimed;
    mapping (address => mapping (uint256 => uint256)) public userRewardsRoundUnclaimed;


    ///////////////
    //CONSTRUCTOR//
    ///////////////

    constructor(address _adminBank) public {
        //set dev bank address and admins
        adminBank = _adminBank;
        admins.push(msg.sender);
        isAdmin[msg.sender] = true;
    }


    /////////////
    //MODIFIERS//
    /////////////

    modifier onlyAdmins() {
        require (isAdmin[msg.sender] == true, "you must be an admin");
        _;
    }

    modifier onlyHumans() {
        require (msg.sender == tx.origin, "only approved contracts allowed");
        _;
      }

    modifier gameOpen() {
        require (gameActive == true || now >= activationTime, "the game must be open");
        if (roundProcessing == true) {
            require (block.number > roundProcessingBegun + RNGblockDelay, "the round is still processing. try again soon");
        }
        _;
    }


        //////////
    //EVENTS//
    //////////

    event adminWithdrew(
        uint256 _amount,
        address indexed _caller,
        string _message
    );

    event cycleStarted(
        address indexed _caller,
        string _message
    );

    event adminAdded(
        address indexed _caller,
        address indexed _newAdmin,
        string _message
    );

    event resolvedEarly(
        address indexed _caller,
        uint256 _pot,
        string _message
    );

    event processingRestarted(
        address indexed _caller,
        string _message
    );

    event contractDestroyed(
        address indexed _caller,
        uint256 _balance,
        string _message
    );

    event userBought(
        address indexed _user,
        uint256 _tokensBought,
        uint256 indexed _roundID,
        string _message
    );

    event userReplayed(
        address indexed _user,
        uint256 _amount,
        string _message
    );

    event userCollected(
        address indexed _user,
        uint256 _amount,
        string _message
    );

    event processingStarted(
        address indexed _caller,
        uint256 indexed _roundID,
        uint256 _blockNumber,
        string _message
    );

    event processingFinished(
        address indexed _caller,
        uint256 indexed _roundID,
        uint256 _blockNumber,
        string _message
    );

    event newRoundStarted(
        uint256 indexed _roundID,
        uint256 _newTokens,
        string _message
    );

    event roundPrizeAwarded(
        uint256 indexed _roundID,
        uint256 _winningNumber,
        uint256 _prize,
        string _message
    );

    event roundAirdropAwarded(
        uint256 indexed _roundID,
        uint256 _winningNumber,
        uint256 _prize,
        string _message
    );

    event cyclePrizeAwarded(
        uint256 _winningNumber,
        uint256 _prize,
        string _message
    );


    ///////////////////
    //ADMIN FUNCTIONS//
    ///////////////////

    function adminWithdraw() external {
        require (isAdmin[msg.sender] == true || msg.sender == adminBank);
        require (adminBalance > 0, "there must be a balance");
        uint256 balance = adminBalance;
        adminBalance = 0;
        adminBank.transfer(balance);

        emit adminWithdrew(balance, msg.sender, "an admin just withdrew to the admin bank");
    }


    //this function begins resolving the round in the event that the game has stalled
    //it can be called no sooner than 1 week after the start of a round
    //can only be called once. can be restarted with restartRound if 256 blocks pass
    function earlyResolveA() external onlyAdmins() onlyHumans() gameOpen() {
        require (now > roundStartTime[roundCount] + 604800 && roundProcessing == false, "earlyResolveA cannot be called yet"); //1 week
        require (roundPrizePot[roundCount].sub(seedAreward).sub(seedBreward) >= 0);

        gameActive = false;
        earlyResolveACalled = true;
        generateSeedA();
    }

    //this function comlpetes the resolution and ends the game
    function earlyResolveB() external onlyAdmins() onlyHumans() {
        require (earlyResolveACalled == true && earlyResolveBCalled == false && roundProcessing == true && block.number > roundProcessingBegun + RNGblockDelay, "earlyResolveB cannot be called yet");

        earlyResolveBCalled = true;
        resolveCycle();

        emit resolvedEarly(msg.sender, cycleProgressivePot, "the cycle was resolved early");
    }

    //resets the first seed in case the processing is not completed within 256 blocks
    function restartRound() external onlyAdmins() onlyHumans() {
        require (roundProcessing == true && block.number > roundProcessingBegun + 256, "restartRound cannot be called yet");

        generateSeedA();

        emit processingRestarted(msg.sender, "round processing was restarted");
    }

    //admins can close the contract no sooner than 30 days after a full cycle completes
    //users need to withdraw funds before this date or risk losing them
    function zeroOut() external onlyAdmins() onlyHumans() {
        require (now >= cycleEnded + 30 days && cycleOver == true, "too early to close the contract");

        //event emited before selfdestruct
        emit contractDestroyed(msg.sender, address(this).balance, "contract destroyed");

        selfdestruct(adminBank);
    }

    //////////////////
    //USER FUNCTIONS//
    //////////////////

    function () external payable onlyHumans() gameOpen() {
        //funds sent directly to contract will trigger buy
        //no refferal on fallback
        buyInternal(msg.value, 0x0);
    }

    function buy(address _referral) public payable onlyHumans() gameOpen() {
        buyInternal(msg.value, _referral);
    }

    function replay(uint256 _amount, address _referral) external onlyHumans() gameOpen() {
        //update userBalance at beginning of function in case user has new funds to replay
        updateUserBalance(msg.sender);

        require (_amount <= userBalance[msg.sender], "insufficient balance");
        require (_amount >= tokenPrice, "you must buy at least one token");

        //take funds from user persistent storage and buy
        userBalance[msg.sender] = userBalance[msg.sender].sub(_amount);

        buyInternal(_amount, _referral);

        emit userReplayed(msg.sender, _amount, "a user replayed");
    }

    function collect() external onlyHumans() {
        //update userBalance at beginning of function in case user has new funds to replay
        updateUserBalance(msg.sender);

        require (userBalance[msg.sender] > 0, "no balance to collect");
        require (userBalance[msg.sender] <= address(this).balance, "you cannot collect more than the contract holds");

        //update user accounting and transfer
        uint256 toTransfer = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        msg.sender.transfer(toTransfer);

        emit userCollect(msg.sender, toTransfer, "a user withdrew");
    }

    //////////////////
    //VIEW FUNCTIONS//
    //////////////////

    //helper function for front end token value
    function getValueOfRemainingTokens() public view returns(uint256 _tokenValue){
        return roundTokensLeft[roundCount].mul(tokenPrice);
    }

    //helper function for front end round prize pot
    function getCurrentRoundPrizePot() public view returns(uint256 _rndPrize){
        return roundPrizePot[roundCount];
    }

    //helper function for front cycle prize pot
    function getCurrentCyclePrizePot() public view returns(uint256 _cyciPrize){
        return cycleProgressivePot[roundCount];
    }

    //helper function to return contract balance
    function contractBalance() external view returns(uint256 _contractBalance) {
        return address(this).balance;
    }

    //check for user rewards available
    function checkUserRewardsAvailable(address _user) external view returns(uint256 _userRewardsAvailable) {
        return userBalance[_user] + checkRewardsMgView(_user) + checkRewardsRndView(_user) + checkPrizesView(_user);
    }

    //user chance of winning round prize or airdrop
    function userOddsRound(address _user) external view returns(uint256) {
        //returns percentage precise to two decimal places (eg 1428 == 14.28% odds)
        return userRoundTokens[_user][roundCount].mul(10 ** 5).div(roundTokensActive[roundCount]).add(5).div(10);
    }

    //user chance of winning cycle prize
    function userOddsCycle(address _user) external view returns(uint256) {
        //returns percentage precise to two decimal places (eg 1428 == 14.28% odds)
        return userTokens[_user].mul(10 ** 5).div(cycleActiveTokens).add(5).div(10);
    }

    //helper function for round data
    function roundInfo() external view returns(
        uint256 _id,
        uint256 _roundTokens,
        uint256 _roundTokensLeft,
        uint256 _roundPrizePot,
        uint256 _roundAirdropPot,
        uint256 _roundStartTime
        ) {

        return (
            roundCount,
            roundTokens[roundCount],
            roundTokensLeft[roundCount],
            roundPrizePot[roundCount],
            roundAirdropPot[roundCount],
            roundStartTime[roundCount]
        );
    }

    //helper function for contract data
    function contractInfo() external view returns(
        uint256 _balance,
        uint256 _volume,
        uint256 _totalBuys,
        uint256 _totalUsers,
        uint256 _tokenSupply,
        uint256 _tokenPrice
        ) {

        return (
            address(this).balance,
            totalVolume,
            totalBuys,
            uniqueAddress.length,
            tokenSupply,
            tokenPrice
        );
    }

    //cycle data
    function cycleInfo() external view returns(
        bool _cycleComplete,
        uint256 _currentRound,
        uint256 _tokenSupply,
        uint256 _progressivePot,
        bool _prizeClaimed,
        uint256 _winningNumber
        ) {
        bool isActive;
        if (roundCount < 100) {
            isActive = true;
            } else {
                isActive = false;
            }

        return (
            isActive,
            roundCount,
            tokenSupply,
            cycleProgressivePot,
            cyclePrizeClaimed,
            cyclePrizeWinningNumber
        );
    }


    //////////////////////
    //INTERNAL FUNCTIONS//
    //////////////////////

    function startCycle() internal {
        require (gameActive == false && cycleCount == 0, "the cycle has already been started");

        gameActive = true;
        cycleStart();
        roundStart();

        emit cycleStarted(msg.sender, "a new cycle just started");
    }

    function buyInternal(uint256 _amount) internal {
        require (_amount >= tokenPrice, "you must buy at least one token");
        require (userRoundTokensMin[msg.sender][roundCount].length < 10, "you are buying too often in this round"); //sets up bounded loop

        //start cycle on first buy
        if (gameActive == false && now >= activationTime) {
            startCycle();
        }

        //update rewards here to prevent overwriting userLastRoundInteractedWith
        if (userLastRoundInteractedWith[msg.sender] < roundCount || roundProcessing == false) {
            updateUserBalance(msg.sender);
        }

        //if this is the first tx after processing period is over, call generateSeedB
        //update user balance here to solve edge case of same user ending a round and starting the next
        if (roundProcessing == true && block.number > roundProcessingBegun + RNGblockDelay) {
            generateSeedB();
            updateUserBalance(msg.sender);
        }

        //track user
        if (knownUsers[msg.sender] == false) {
            uniqueAddress.push(msg.sender);
            knownUsers[msg.sender] = true;
        }

        //assign tokens
        uint256 tokensPurchased;
        uint256 tronSpent = _amount;
        uint256 valueOfRemainingTokens = roundTokensLeft[roundCount].mul(tokenPrice);

        //if round tokens are all sold, push difference to user balance and call generateSeedA
        if (tronSpent >= valueOfRemainingTokens) {
            uint256 incomingValue = tronSpent;
            tronSpent = valueOfRemainingTokens;
            tokensPurchased = roundTokensLeft[roundCount];
            roundTokensLeft[roundCount] = 0;
            uint256 tronCredit = incomingValue.sub(tronSpent);
            userBalance[msg.sender] += tronCredit;
            generateSeedA();
        } else {
            tokensPurchased = tronSpent.div(tokenPrice);
        }

        //update user token accounting
        userTokens[msg.sender] += tokensPurchased;
        roundGameTokens[msg.sender][roundCount] += tokensPurchased;
        //add min ranges and save in user accounting
        userRoundTokensMin[msg.sender][roundCount].push(cycleActiveTokens + 1);
        userRoundTokensMax[msg.sender][roundCount].push(cycleActiveTokens + tokensPurchased);
        //log last eligible rounds for withdraw checking
        userLastRoundInteractedWith[msg.sender] = roundCount;

        //divide amount by various percentages and distribute
        uint256 adminShare = tronSpent.mul(adminFeeRate).div(100);
        adminBalance += adminShare;

        uint256 roundRewardShare = tronSpent.mul(roundRewardRate).div(100);
        roundRewards[roundCount] += roundRewardShare;

        uint256 roundPrize = tronSpent.mul(roundPotRate).div(100);
        roundPrizePot[roundCount] += roundPrize;

        uint256 roundAirdrop = tronSpent.mul(roundAirdropRate).div(100);
        roundAirdropPot[roundCount] += roundAirdrop;

        uint256 cyclePot = tronSpent.mul(progressivePotRate).div(100);
        cycleProgressivePot += cyclePot;

        //update global token accounting
        if (roundTokensLeft[roundCount] > 0) {
            roundTokensLeft[roundCount] = roundTokensLeft[roundCount].sub(tokensPurchased);
        }
        cycleActiveTokens += tokensPurchased;
        roundTokensActive[roundCount] += tokensPurchased;
        roundTokensActive[roundCount] += tokensPurchased;
        totalVolume += tronSpent;
        totalBuys++;

        //update user balance, if necessary. done here to keep ensure updateUserBalance never has to search through multiple rounds
        updateUserBalance(msg.sender);

        emit userBought(msg.sender, tokensPurchased, roundCount, "a user just bought tokens");
    }

    function checkRewards(address _user) internal {
        //set up local shorthand
        uint256 _rnd = userLastRoundInteractedWith[_user];

        //calculate round rewards
        userShareRound[_user][_rnd] = userRoundTokens[_user][_rnd].mul(10 ** (precisionFactor + 1)).div(roundTokensActive[_rnd] + 5).div(10);
        userRewardsRoundTotal[_user][_rnd] = roundRewards[_rnd].mul(userShareRound[_user][_rnd]).div(10 ** precisionFactor);
        userRewardsRoundUnclaimed[_user][_rnd] = userRewardsRoundTotal[_user][_rnd].sub(userRewardsRoundClaimed[_user][_rnd]);
        //add to user balance
        if (userRewardsRoundUnclaimed[_user][_rnd] > 0) {
            //sanity check
            assert(userRewardsRoundUnclaimed[_user][_rnd] <= roundRewards[_rnd]);
            assert(userRewardsRoundUnclaimed[_user][_rnd] <= address(this).balance);
            //update user accounting
            userRewardsRoundClaimed[_user][_rnd] = userRewardsRoundTotal[_user][_rnd];
            uint256 shareTempRnd = userRewardsRoundUnclaimed[_user][_rnd];
            userRewardsRoundUnclaimed[_user][_rnd] = 0;
            userBalance[_user] += shareTempRnd;
            roundRewardsClaimed[_rnd] += shareTempRnd;
        }
    }

    function checkPrizes(address _user) internal {
        //don't check for prizes on the first buy of the round
        if (roundProcessing == false) {
            //push cycle prizes to persistent storage
            if (cycleOver == true && userCycleChecked[_user] == false) {
                //get round cycle prize was in
                uint256 mg = cyclePrizeInRound;
                //check if user won cycle prize
                if (cyclePrizeClaimed == false && userRoundTokensMax[_user][mg].length > 0) {
                    //check if user won round
                    //loop iterations bounded to a max of 10 on buy()
                    for (uint256 i = 0; i < userRoundTokensMin[_user][mg].length; i++) {
                        if (cyclePrizeWinningNumber >= userRoundTokensMin[_user][rnd][i] && cyclePrizeWinningNumber <= userRoundTokensMax[_user][rnd][i]) {
                            userBalance[_user] += cycleProgressivePot;
                            cyclePrizeClaimed = true;
                            cyclePrizeWinner = msg.sender;
                            break;
                        }
                    }
                }
                userCycleChecked[_user] = true;
            }

            //push round prizes to persistent storage
            if (userLastRoundChecked[_user] < userLastRoundInteractedWith[_user] && roundCount >= userLastRoundInteractedWith[_user] && roundPrizeClaimed[userLastRoundInteractedWith[_user]] == false) {
                //check if user won round
                rnd = userLastMiniGameInteractedWith[_user];
                for (i = 0; i < userRoundTokensMin[_user][rnd].length; i++) {
                    if (roundPrizeNumber[rnd] >= userRoundTokensMin[_user][rnd][i] && roundPrizeNumber[rnd] <= userRoundTokensMax[_user][rnd][i]) {
                        userBalance[_user] += roundPrizePot[rnd];
                        roundPrizeClaimed[rnd] = true;
                        roundPrizeWinner[rnd] = msg.sender;
                        break;
                    }
                }

                //check if user won airdrop
                for (i = 0; i < userRoundTokensMin[_user][rnd].length; i++) {
                    if (roundAirdropNumber[rnd] >= userRoundTokensMin[_user][rnd][i] && roundAirdropNumber[rnd] <= userRoundTokensMax[_user][rnd][i]) {
                        userBalance[_user] += roundAirdropPot[rnd];
                        roundAirdropClaimed[rnd] = true;
                        roundAirdropWinner[rnd] = msg.sender;
                        break;
                    }
                }
                //update last round checked
                userLastRoundChecked[_user] = userLastRoundInteractedWith[_user];
            }
        }
    }

    function updateUserBalance(address _user) internal {
        checkRewards(_user);
        checkPrizes(_user);
    }

    function roundStart() internal {
        require (cycleOver == false, "the cycle cannot be over");

        roundCount++;
        roundStartTime[roundCount] = now;
        //set up special case for correct token range on first round
        if (tokenSupply != 0) {
            roundTokenRangeMin[roundCount] = tokenSupply + 1;
        } else {
            roundTokenRangeMin[roundCount] = 0;
        }
        //generate tokens and update accounting
        roundTokens[roundCount] = generateTokens();
        roundTokensLeft[roundCount] = roundTokens[roundCount];
        roundTokenRangeMax[roundCount] = tokenSupply;

        //award prize if cycle is complete
        if (roundCount % (roundsPerCycle + 1) == 0 && roundCount > 1) {
            awardCyclePrize();
        }

        emit newRoundStarted(roundCount, roundTokens[roundCount], "new round started");
    }

    function cycleStart() internal {
        require (cycleOver == false, "the cycle cannot be over");

        cycleCount++;
        cycleStartTime = now;
    }

    function generateTokens() internal returns(uint256 _tokens) {
        bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 randTokens = uint256(hash).mod(minTokensPerRound);
        uint256 newRoundTokens = randTokens + minTokensPerRound;
        tokenSupply += newRoundTokens;
        salt++;

        return newRoundTokens;
    }

    function generateSeedA() internal {
        require (roundProcessing == false || roundProcessing == true && block.number > roundProcessingBegun + 256, "seed A cannot be regenerated right now");
        require (roundTokensLeft[roundCount] == 0 || earlyResolveACalled == true, "active tokens remain in this round");

        roundProcessing = true;
        roundProcessingBegun = block.number;
        //generate seed
        hashA = blockhash(roundProcessingBegun - 1);
        //log end times
        if (roundCount > 1) {
            roundEndTime[roundCount] = now;
        }
        //award processing bounty
        if (roundSeedAawarded[roundCount] == false) {
            userBalance[msg.sender] += seedAreward;
            roundSeedAawarded[roundCount] = true;
        }
        salt++;

        emit processingStarted(msg.sender, roundCount, block.number, "processing started");
    }

    function generateSeedB() internal {
        //gererate seed
        hashB = blockhash(roundProcessingBegun + RNGblockDelay);
        //awared prizes
        awardRoundPrize();
        awardRoundAirdrop();
        //award processing bounty
        if (roundSeedBawarded[roundCount] == false) {
            userBalance[msg.sender] += seedBreward;
            roundSeedBawarded[roundCount] = true;
        }
        //start next round
        roundStart();
        roundProcessing = false;
        salt++;

        emit processingFinished(msg.sender, roundCount, block.number, "processing finished");
    }

    function awardRoundPrize() internal {
        bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(roundTokens[roundCount].sub(roundTokensLeft[roundCount]));
        roundPrizeNumber[roundCount] = winningNumber + roundTokenRangeMin[roundCount];
        roundPrizePot[roundCount] = roundPrizePot[roundCount].sub(seedAreward).sub(seedBreward);
        salt++;

        emit roundPrizeAwarded(roundCount, winningNumber, roundPrizePot[roundCount], "round prize awarded");
    }

    function awardRoundeAirdrop() internal {
        bytes32 hash = keccak256(abi.encodePacked(salt, hashB, hashA));
        uint256 winningNumber = uint256(hash).mod(roundTokens[roundCount].sub(roundTokensLeft[roundCount]));
        roundAirdropNumber[roundCount] = winningNumber + roundTokenRangeMin[roundCount];
        salt++;

        emit roundAirdropAwarded(roundCount, winningNumber, roundAirdropPot[roundCount], "round airdrop awarded");
    }

    function awardCyclePrize() internal {
        bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber;
        if (roundCount > 1) {
            winningNumber = uint256(hash).mod(roundTokenRangeMax[roundCount - 1]);
        //handles edge case of early resolve during the first round
        } else if (roundCount == 1) {
            winningNumber = uint256(hash).mod(roundTokensActive[1]);
        }
        cyclePrizeWinningNumber = winningNumber;
        gameActive = false;
        cycleEnded = now;
        cycleOver = true;
        narrowCyclePrize();
        salt++;

        emit cyclePrizeAwarded(winningNumber, cycleProgressivePot, "cycle prize awarded");
    }

    function resolveCycle() internal {
        //generate hashB here in instead of calling generateSeedB
        hashB = blockhash(roundProcessingBegun + RNGblockDelay);
        //award prizes
        awardRounddPrize();
        awardRoundAirdrop();
        awardCyclePrize();
        //close game
        roundProcessing = false;
        gameActive = false;
    }

    //narrows down the token range of a cycle to a specific round
    //reduces the search space on user prize updates
    function narrowCyclePrize() internal returns(uint256 _roundID) {
        //set up minigame local accounting
        uint256 roundRangeMin;
        uint256 roundRangeMax;
        uint256 _ID = cyclePrizeInRound;
        roundRangeMin = 1;
        roundRangeMax = roundsPerCycle;
        //loop through each round to check prize number
        //log globaly so this only needs to be called once per prize
        for (i = roundRangeMin; i <= roundRangeMax; i++) {
            if (cyclePrizeWinningNumber >= roundTokenRangeMin[i] && cyclePrizeWinningNumber <= roundTokenRangeMax[i]) {
                cyclePrizeInRound = i;
                cyclePrizeTokenRangeIdentified = true;
                return cyclePrizeInRound;
                break;
            }
        }
    }

    //helper function for up to date front end balances without state change
    function checkRewardsRndView(address _user) internal view returns(uint256 _rewards) {
        //set up local shorthand
        uint256 _rnd = userLastRoundInteractedWith[_user];
        uint256 rndShare = userShareRound[_user][_rnd];
        uint256 rndTotal = userRewardsRoundTotal[_user][_rnd];
        uint256 rndUnclaimed = userRewardsRoundUnclaimed[_user][_rnd];
        //calculate round rewards
        rndShare = userRoundTokens[_user][_rnd].mul(10 ** (precisionFactor + 1)).div(roundTokens[_rnd] + 5).div(10);
        rndTotal = roundRewards[_rnd].mul(rndShare).div(10 ** precisionFactor);
        rndUnclaimed = rndTotal.sub(userRewardsRoundClaimed[_user][_rnd]);

        return rndUnclaimed;
    }

    //helper function for up to date front end balances without state change
    function checkPrizesView(address _user) internal view returns(uint256 _prizes) {
        //local accounting
        uint256 prizeValue;
        //push cycle prizes to persistent storage
        if (cycleOver == true && userCycleChecked[_user] == false) {
            //get round cycle prize was in
            uint256 rnd;
            if (cyclePrizeTokenRangeIdentified == true) {
                rnd = cyclePrizeInRound;
            } else {
                narrowCyclePrizeView();
                rnd = cyclePrizeInRound;
            }
            //check if user won cycle prize
            if (cyclePrizeClaimed == false && userRoundTokensMax[_user][rnd].length > 0) {
                //check if user won round
                //loop iterations bounded to a max of 10 on buy()
                for (uint256 i = 0; i < userRoundTokensMin[_user][rnd].length; i++) {
                    if (cyclePrizeWinningNumber >= userRoundTokensMin[_user][rnd][i] && cyclePrizeWinningNumber <= userRoundTokensMax[_user][rnd][i]) {
                        prizeValue += cycleProgressivePot;
                        break;
                    }
                }
            }
        }
        //push round prizes to persistent storage
        if (userLastRoundChecked[_user] < userLastRoundInteractedWith[_user] && roundCount >= userLastRoundInteractedWith[_user] && roundPrizeClaimed[userLastRoundInteractedWith[_user]] == false) {
                //check if user won round
            rnd = userLastRoundInteractedWith[_user];
            for (i = 0; i < userRoundTokensMin[_user][rnd].length; i++) {
                if (roundPrizeNumber[rnd] >= userRoundTokensMin[_user][rnd][i] && roundPrizeNumber[rnd] <= userRoundTokensMax[_user][rnd][i]) {
                    prizeValue += roundPrizePot[rnd];
                    break;
                }
            }
            //check if user won airdrop
            for (i = 0; i < userRoundTokensMin[_user][rnd].length; i++) {
                if (roundAirdropNumber[mg] >= userRoundTokensMin[_user][rnd][i] && roundAirdropNumber[rnd] <= userRoundTokensMax[_user][rnd][i]) {
                    prizeValue += roundAirdropPot[mg];
                    break;
                }
            }
        }
        return prizeValue;
    }

    //helper function for up to date front end balances without state change
    function narrowCyclePrizeView() internal view returns(uint256 _roundID) {
        //set up local accounting
        uint256 winningNumber = cyclePrizeWinningNumber;
        uint256 roundRangeMin;
        uint256 roundRangeMax;
        uint256 _ID = rnd;
        roundRangeMin = 1;
        roundRangeMax = miniGamesPerRound;
            //loop through each minigame to check prize number
            //log globaly so this only needs to be called once per prize
        for (i = roundRangeMin; i <= roundRangeMax; i++) {
            if (winningNumber >= roundTokenRangeMin[i] && winningNumber <= roundTokenRangeMax[i]) {
                return i;
                break;
            }
        }
    }
}

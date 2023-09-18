pragma solidity ^0.4.24;

import "./safeMath.sol";

/**
 * @title  - DecentralisedLottery
 * @author - Vutsal Singhal <vutsalsinghal[at]gmail[dot]com>
 * @notice - This is a type of coin flip lottery (instead of Lotto lottery).
                  But instead of binary coin-flip, it can ternary, quaternary, ..., etc.
 * @dev    - A completely decentralised lottery
 */
 contract DecentralisedLottery{

    // library declaration
    using SafeMath for uint256;
    
    // ------------------ Variables -----------------\\
    
    address owner;
    uint public winningChoice;                                       // randomly generated choice (after lottery ends)
    bool winningChoiceSet;
    uint public timeToDraw;                                          // time when lottery ends (set by owner)
    uint public encashDuration;                                      // duration (after lottery ended) during which 
                                                                          // participants can get their profits (default: 1 day)
    uint public lastParticipator;                                    // keep track of total participants
    uint public totWinners;                                          // total no.of lottery winners!
    uint public profitAmt;                                           // (total pot)/(total winners)
    uint public buyIn;                                               // minimum amount to be eligible to participate
    uint public participationFee;                                    // owners cut
    
    struct Participator{
        address sender;
        uint choice;
        uint bettingTime;
        bool profitReceived;
    }
    
    // ------------------ Mappings -----------------\\
    
    mapping (uint => Participator) participatorInfo;
    mapping (address => uint) addrToID;
    mapping (address => bool) alreadyApproved;
    mapping (uint => uint) public options;                           // options from which participants can choose to place bet
    
    // ------------------ Modifiers -----------------\\
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier lotteryOnGoing {
        require(now < timeToDraw);
        _;
    }

    modifier lotteryEnded {
        require(now >= timeToDraw);
        _;
    }

    modifier encashDurationOngoing {
        require(now >= timeToDraw && now < encashDuration);
        _;
    }

    modifier encashDurationEnded {
        require(now >= encashDuration);
        _;
    }
    
    // ------------------ Constructor -----------------\\
    
    constructor() public{
        owner = msg.sender;
        winningChoice = 0;
        winningChoiceSet = false;
        timeToDraw = now;
        encashDuration = now;
        lastParticipator = 0;
        totWinners = 0;
        profitAmt = 0;
        buyIn = 0.5 ether;
        participationFee = 0.0001 ether;
        options[1] = 1;
        options[2] = 2;
        options[3] = 3;
    }

    // ------------------ Public/External functions -----------------\\

    function placeBet(uint _playerChoice) public lotteryOnGoing payable{
    // Function to place bet (choose an option)
        require(msg.value >= buyIn.add(participationFee), "Amount < (Buy-in + Participation fee)");
        require(alreadyApproved[msg.sender] != true, "You've already placed your bet!");

        lastParticipator = lastParticipator.add(1);                             // using safemath syntax
        uint _participatorNo = lastParticipator;
        if (options[_playerChoice] != 0){
            participatorInfo[_participatorNo].choice = options[_playerChoice];
        }else{
            lastParticipator = lastParticipator.sub(1);                         // using safemath syntax
            require(false, "Choose valid option!");                             // Throw error
        }

        participatorInfo[_participatorNo].sender = msg.sender;
        participatorInfo[_participatorNo].bettingTime = now;
        participatorInfo[_participatorNo].profitReceived = false;
        addrToID[msg.sender] = _participatorNo;
        alreadyApproved[msg.sender] = true;
    }

    function getParticipatorInfo() view public returns (address senderAddr, uint choice, uint timeOfBet, bool profitReceived){
    // Each participant can view his and only his info!
        uint _userID = addrToID[msg.sender];
        if (msg.sender == participatorInfo[_userID].sender){
            return (participatorInfo[_userID].sender, participatorInfo[_userID].choice, participatorInfo[_userID].bettingTime, participatorInfo[_userID].profitReceived);
        }else{
            // Not authorised!
            return (msg.sender,0,0,false);
        }
    }

    function getProfits() public encashDurationOngoing{
    // When the lottery ends, winners can call this function to receive their winnings
        require(alreadyApproved[msg.sender], 'You did not participate in the lottery');

        if (profitAmt == 0) calProfit();                                        // Just making sure! (already called for the 1st time inside setWiningChoice() by owner)
         
        uint _userID = addrToID[msg.sender];
        require(!participatorInfo[_userID].profitReceived, "You've already received the profits!");
        if (participatorInfo[_userID].choice == winningChoice){
            if (participatorInfo[_userID].bettingTime < timeToDraw){            // Dont disburse profits to those who made bet after timeToDraw
                participatorInfo[_userID].profitReceived = true;
                alreadyApproved[msg.sender] = false;
                (msg.sender).transfer(profitAmt);
            }
        }
    }
    
    function totalPot() view public returns(uint){
    // Function to view value in total lottery pot (in wei)
        return buyIn.mul(lastParticipator);
    }

    function timeLeft() view external lotteryOnGoing returns(uint time_left){
    // Function to display time (in seconds) left until lottery ends
        if (now < timeToDraw){
            return timeToDraw.sub(now);
        }else{
            return 0;
        }
    }

    function timeLeftToEncash() view external encashDurationOngoing returns(uint time_left){
        // Function to display time (in seconds) left until participants can get their profits
        if (now < encashDuration){
            return encashDuration.sub(now);
        }else{
            return 0;
        }
    }

    // ------------------ OnlyOwner/Internal functions -----------------\\
    
    function calProfit() internal{
    // Internal function to calculate the profits each winner will receive!
        require(winningChoice != 0, "Owner has not yet set the 'winning choice'!");
        for (uint i=1; i<lastParticipator+1; i++){
            if (participatorInfo[i].bettingTime < timeToDraw){                  // Dont include users who made bet after timeToDraw
                if (participatorInfo[i].choice == winningChoice){
                    totWinners = totWinners.add(1);                             // using safemath syntax
                }
            }
        }
        if (totWinners != 0) profitAmt = totalPot().div(totWinners);            // using safemath syntax
    }

    function currentTime() view external onlyOwner returns(uint){
    // Helper function to set timeToDraw
        return now;
    }

    function setWiningChoice(uint _randomChoice) external onlyOwner encashDurationOngoing{
    // Function to set the "lottery winning" choice randomly using external source (eg. Oracles)
        require(winningChoiceSet != true);                                      // Check if winning choice is not already set!

        winningChoice = _randomChoice;
        winningChoiceSet = true;
        encashDuration = now.add(24 hours);                                     // start the encash duration

        // call function to calculate profits
        if (profitAmt == 0) calProfit();
    }

    function setTimeToDraw(uint _timeToDraw) external onlyOwner encashDurationEnded{
    // Function to (re)set "when" the lottery ends!
        timeToDraw = _timeToDraw;
        encashDuration = _timeToDraw.add(24 hours);
            
        // Reset values
        for (uint i=1; i<lastParticipator+1; i++){
            addrToID[participatorInfo[i].sender] = 0;
            alreadyApproved[participatorInfo[i].sender] = false;

            delete participatorInfo[i];
        }
            
        winningChoice = 0;
        winningChoiceSet = false;
        totWinners = 0;
        lastParticipator = 0;
        profitAmt = 0;
    }

    function setOptions(uint[] _array) external onlyOwner lotteryEnded{
    // Function to add or remove options
        for (uint i=0;i<_array.length-1;i+2){
            uint key = _array[i];
            uint val = _array[i++];
            options[key] = val;
        }
    }

    function setEncashDuration(uint _newDuration) external onlyOwner encashDurationOngoing{
    // Function to change encash duration (if need be)      
        encashDuration = _newDuration;
    }
        
    function transferParticipationFee() external onlyOwner lotteryEnded{
    // transfer participation fee to owner
        uint _amt = participationFee * lastParticipator;
        owner.transfer(_amt);
    }

    function setAmt(uint _buyIn, uint _participationFee) external onlyOwner lotteryEnded{
    // set buy-in and participation fee of the user
        buyIn = _buyIn;
        participationFee = _participationFee;
    }

    function transferEther(uint amount) external onlyOwner encashDurationEnded{
    // transfer ether to owner
        owner.transfer(amount);
    }

    function kill() public onlyOwner{
    // destroy contract
        selfdestruct(owner);
    }
}

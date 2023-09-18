pragma solidity >=0.4.0 <0.6.0;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./OraclizeAPI.sol";

contract Lottery is usingOraclize, Pausable {
    using SafeMath for uint;

    // ticket's price in finney
    uint public ticketPrice;
    uint public endingTime;
    uint public ticketsSold;
    uint public uniqueOwners;
    // maximum total ticket amount available in this lottery
    // if the value is 1, then there is no limit - infinite tickets
    // lottery will only end when it reaches 'endingTime'
    uint public ticketAmount;
    // number of tickets each user can buy
    uint public ticketsPerPerson;
    // contract's owner will receive a fee from winner's price
    // 10 == 10%
    uint public fee;
    // shows which bought ticket was a lucky one
    uint public winner;
    // winner's address
    address payable public winnerAddress;
    
    // make sure processWinnings() will only be called once
    bool winningsProcessed = false;
    // make sure finishLottery() will only be called once
    bool finished;

    event LotteryCreated(uint ticketPrice, uint endingTime, uint ticketAmount, uint ticketsPerPerson, uint fee);
    event LotteryCanceled(); 
    event LotteryFinished(address winner, uint ticketsSold, uint amountWon); 
    event TicketPurchased(address buyer);
    event NewOraclizeQuery(string description);
    event RandomNumberGenerated(uint number);

    enum State {Active, Inactive}
    State state;

    // array of unique owners, no duplicates
    address payable[] public uniqueTicketOwners;
    // each ticket's number corresponds to its buyer
    mapping (uint => address payable) ticketToOwner;
    // shows how many tickets each buyer has
    mapping (address => uint) public ownerTicketCount;
    // stores oraclize query ids, is used to confirm that the received response from oraclize
    // is not malicious
    mapping(bytes32=>bool) validIds;


    /**
    * @dev For an unlimited amount of tickets in the lottery for its duration, set ticketAmount = 1.
    * @param _ticketPrice price of each ticket in finney
    * @param _ticketsPerPerson amount of tickets one user can buy
    * @param _fee fee that owners receives from the winning price
    * @dev 10 fee == 10% fee
    * @param _endingTime lottery's ending time in UTC.
    * @param _ticketAmount maximum amount of tickets to be sold in the lottery 
    */
    constructor(uint _ticketPrice, uint _ticketsPerPerson, uint _fee, uint _endingTime, uint _ticketAmount) public {
        require(_ticketPrice > 0, "Invalid ticket price");
        require(_endingTime > block.timestamp, "Invalid ending time");
        require(_ticketAmount > 0, "Invalid ticket amount");
        ticketPrice = _ticketPrice * 1 finney;
        ticketsPerPerson = _ticketsPerPerson;
        fee = _fee;
        endingTime = _endingTime;
        ticketAmount = _ticketAmount;
        ticketsSold = 0;
        state = State.Active;
        finished = false;
        // for testing on local blockchain only!
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
    }

    /**
    * @dev Copy of constructor, used to reinitiate lottery
    * @dev For an unlimited amount of tickets in the lottery for its duration, set ticketAmount = 1.
    * @param _ticketPrice price of each ticket in finney
    * @param _ticketsPerPerson amount of tickets one user can buy
    * @param _fee fee that owners receives from the winning price
    * @dev 10 fee == 10% fee
    * @param _endingTime lottery's ending time in UTC.
    * @param _ticketAmount maximum amount of tickets to be sold in the lottery 
    */
    function restartLottery(uint _ticketPrice, uint _ticketsPerPerson, uint _fee, uint _endingTime, uint _ticketAmount) public onlyOwnerAndAdmin {
        require(state == State.Inactive, "Lottery is active");
        require(ticketsSold == 0 && uniqueOwners == 0 && endingTime == 0, "Lottery must be cleaned");
        require(_ticketPrice > 0, "Invalid ticket price");
        require(_endingTime > block.timestamp, "Invalid ending time");
        require(_ticketAmount > 0, "Invalid ticket amount");
        ticketPrice = _ticketPrice * 1 finney;
        ticketsPerPerson = _ticketsPerPerson;
        fee = _fee;
        endingTime = _endingTime;
        ticketAmount = _ticketAmount;
        winnerAddress = address(0);
        winningsProcessed = false;
        state = State.Active;
        finished = false;
        emit LotteryCreated(ticketPrice, endingTime, ticketAmount, ticketsPerPerson, fee);
    }

    /**
    * @dev we do not accept donations
    */
    function() external payable {
        buyTicket();
    }

    /**
    * @dev clean's every mapping and array, prepares variables for the next lottery
    */
    function _cleanLottery() internal {
        for (uint i = 0; i < uniqueOwners; i++) {
            delete ownerTicketCount[uniqueTicketOwners[i]];
        }
        for (uint k = 0; k < uniqueOwners; k++) {
            delete uniqueTicketOwners[k];
        }
        uniqueTicketOwners.length = 0;
        for (uint j = 0; j < ticketsSold; j++) {
            delete ticketToOwner[j];
        }
        endingTime = 0;
        ticketsSold = 0;
        uniqueOwners = 0;
        ticketsPerPerson = 0;
        state = State.Inactive;
    }

    /**
    * @dev function accepts only the exact amount of finney. Sending more than ticket's price will revert
    */
    function buyTicket() public payable {
        require(!_lotteryEnded(), "Lottery has finished.");
        require(ownerTicketCount[msg.sender] < ticketsPerPerson, "You already have the maximum amount of tickets.");
        require(msg.value == ticketPrice, "Incorrect sum paid");
        // store ticket's owner in the mapping
        ticketToOwner[ticketsSold] = msg.sender;
        // increment ticketsSold variable
        ticketsSold = ticketsSold.add(1);
        // increment buyer's ticket amount
        ownerTicketCount[msg.sender] = ownerTicketCount[msg.sender].add(1);
        // if the buyer didn't own any tickets before, add the buyer to uniqueTicketOwners array
        if(ownerTicketCount[msg.sender] == 1) {
            uniqueTicketOwners.push(msg.sender);
            uniqueOwners = uniqueOwners.add(1);
        }
        // tell the world that someone bought the ticket
        emit TicketPurchased(msg.sender);
    } 

    /**
    * @dev AVOID USING THIS FUNCTION, VERY EXPENSIVE
    * @dev Cancels the lottery by setting the ending time to the current time, then returns ticket sales
    */
    function cancelLottery() public onlyOwnerAndAdmin {
        endingTime = block.timestamp;
        for(uint i = 0; i < uniqueOwners; i++) { //  Checks-Effects-Interactions pattern (https://solidity.readthedocs.io/en/develop/security-considerations.html#re-entrancy)
            uint refundAmount = ownerTicketCount[uniqueTicketOwners[i]] * ticketPrice;
            ownerTicketCount[uniqueTicketOwners[i]] = 0;
            uniqueTicketOwners[i].transfer(refundAmount);
        }
        emit LotteryCanceled();
        // prepare the contract for the next lottery
        _cleanLottery();
    }

    /**
    * @dev If ticketAmount is greater than 1, compare number to ticketsSold. 
    *      Check if timestamp >= endingTime either way. 
    *      If either condition is true, the lottery is ended.
    */
    function _lotteryEnded() private view returns (bool) {
        return (ticketAmount != 1) ? (ticketAmount == ticketsSold || block.timestamp >= endingTime) : block.timestamp >= endingTime;
    }

    /**
    * @dev Check if every condition for ending the lottery is met
    */
    function finishLottery() public onlyOwnerAndAdmin {
        require(_lotteryEnded(), "Lottery is still ongoing.");
        require(!finished, "finishLottery was already called");
        finished = true;
        _generateWinner();
    }

    /**
    * @dev send an Oraclize query to WolframAlpha asking for a random lottery winner
    */
    function _generateWinner() internal {
        emit NewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
        bytes32 queryId = oraclize_query("WolframAlpha", strConcat("random integer between 0 and ", uint2str(ticketsSold-1)));
        validIds[queryId] = true;
    }

    /**
    * @dev Oraclize returns the result to this function
    * @param myid is used to check if it was a valid query previously made by this contract
    * @param result random lucky winner's number
    */
    function __callback(bytes32 myid, string memory result) public {
        require(msg.sender == oraclize_cbAddress(), "msg.sender is not Oraclize");
        require(validIds[myid]);
        // convert the result from string to uint
        winner = parseInt(result); 
        // set winner's address
        winnerAddress = ticketToOwner[winner];
        // Let the world know the lucky number
        emit RandomNumberGenerated(winner);
    }
    
    /**
    * @dev transfer winner's ether, take owner's fee and call _cleanLottery
    */
    function processWinnings() external onlyOwnerAndAdmin {
        require(winnerAddress != address(0), "Oracle's did not complete the query yet");
        require(winningsProcessed == false, "Winnings were already processed");
        uint amountWon = ticketsSold.mul(ticketPrice);
        uint winningFee = amountWon.mul(fee).div(100);
        amountWon = amountWon.sub(winningFee);
        
        winnerAddress.transfer(amountWon);
        owner.transfer(address(this).balance);
        
        winningsProcessed = true;
        
        emit LotteryFinished(winnerAddress, ticketsSold, amountWon);
        _cleanLottery();
    }
    
    /**
    * @dev returns if the ended or not
    */
    function lotteryEnded() public view returns(bool){
        return _lotteryEnded();
    }
}
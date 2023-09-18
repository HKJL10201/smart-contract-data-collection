// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../contracts/Owner.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";


contract LotteryContract is Owner, VRFV2WrapperConsumerBase, ConfirmedOwner {

    // ---------- VARIABLES, MAPPINGS AND MODIFIERS: ----------

    // TODO: variables should be reviewed to check if we could save gas using different declarations for them
    struct LotteryStruct {
        uint ticketPrice;
        uint ticketsAmount;
        uint amountOfDays;
        uint potAmount;
        uint startingTimestamp;
        bool InEndingProcess;
    }

    LotteryStruct public Lottery;

    uint feesToWithdraw;

    mapping (uint => address payable) public ticketToOwner;
    address [] lotteryBuyers;

    address [] notRefundedBuyers;

    // checks if there is a lottery still active by comparing timestamps
    modifier isLotteryActive() {
        require(
            (Lottery.startingTimestamp != 0) &&
            (((block.timestamp - Lottery.startingTimestamp) / 60 / 60 / 24) < Lottery.amountOfDays),
            "No lottery running"
        );
        _;
    }

    // checks if there isn't another lottery still active by comparing timestamps
    modifier isLotteryInactive() {
        require(
            (Lottery.startingTimestamp == 0) ||
            (((block.timestamp - Lottery.startingTimestamp) / 60 / 60 / 24) >= Lottery.amountOfDays),
            "A lottery is stil running"
        );
        _;
    }

    // ---------- EVENTS DECLARATION: ----------
    event StartedEndLotteryProcessEvent(address callerAddress, uint id);
    event EndedEndLotteryProcessEvent(address winner, uint amountTransfered);
    event StartedLotteryEvent(LotteryStruct lotteryCreated);
    event TicketBoughtEvent(address buyerAddress, uint ticketNumber, uint newAmountOfTickets, uint newPotAmount);
    event FeesWithdrewEvent(uint feesWithdrew);
    event TicketPriceChangedEvent(uint oldPrice, uint newPrice);
    event LotteryCanceledEvent(uint buyersRefunded, uint buyersNotRefunded);
    event SubmissionOfFoundsRetriedEvent(uint successfulBuyersRefunded, uint UnsuccessfulBuyersRefunded);

    // ---------- CHAINLINK FUNCTIONS AND VARIABLES: ----------

    /* depends on the number of requested values that you want sent to the
       fulfillRandomWords() function. Test and adjust
       this limit based on the network that you select, the size of the request,
       and the processing of the callback request in the fulfillRandomWords()
       function. */
    uint32 callbackGasLimit = 100000;
    // the default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    /* for this example, retrieve 2 random values in one request.
       cannot exceed VRFV2Wrapper.getConfig().maxNumWords. */
    uint32 numWords = 1;
    // address LINK - hardcoded for Goerli
    address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // address WRAPPER - hardcoded for Goerli
    address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    // 
    uint256 public randomResult;

    constructor() 
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) 
    {}

    /* ends the lottery by calling the winner
       this function calls the oracle that instead calls the "fulfillRandomWords"
       since the call of the other function takes some time, we need to protect the function of being called multiple times,
       hence the "Lottery.InEndingProcess" variable */
    function endLottery() public isLotteryInactive returns (uint256 requestId) {
        require(Lottery.potAmount > 0, "There is no pot to claim");
        require(!Lottery.InEndingProcess, "Lottery in ending process");
        Lottery.InEndingProcess = true;
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        emit StartedEndLotteryProcessEvent(msg.sender, requestId);
    }

    /* this function is called by the oracle and sends the founds of the lottery to the winner, less a 2% fee
       it is secured by the VRFV2WrapperConsumerBase contract, and as such can't be called by malicious actors */
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomness) internal virtual override  {
        randomResult = randomness[0] % (Lottery.ticketsAmount);
        uint amountToTransfer = Lottery.potAmount - (Lottery.potAmount * 2 / 100);
        /* TODO: "transfer" function can revert, and "fulfillRandomWords" should never revert, accordingly to the chainlink documentation
           (source: https://docs.chain.link/vrf/v2/security/#fulfillrandomwords-must-not-revert)
           to fix this, we either should make a synchronous call of this code or run an Automation Node that make this call in another function
           for now, it's like this due to convenience when using the contract and to not use a chainlink subscription (for the Automation Node) */
        ticketToOwner[randomResult].transfer(amountToTransfer);
        Lottery.potAmount = 0;
        Lottery.InEndingProcess = false;
        emit EndedEndLotteryProcessEvent(ticketToOwner[randomResult], amountToTransfer);
    }

    // ---------- HAPPY FLOW: ----------

    // starts a lottery
    function startLottery(uint _amountOfDays, uint _ticketPrice) external isOwner isLotteryInactive {
        require(Lottery.potAmount == 0, "There is already one lottery running with a pot");
        // ticket price in Wei
        Lottery.ticketPrice = _ticketPrice;
        Lottery.ticketsAmount = 0;
        Lottery.amountOfDays = _amountOfDays;
        Lottery.startingTimestamp = block.timestamp;
        emit StartedLotteryEvent(Lottery);
    }

    // buys a lottery ticket
    function buyTicket() payable external isLotteryActive returns(uint tickedId) {
        require(msg.value == Lottery.ticketPrice);
        ticketToOwner[Lottery.ticketsAmount] = payable(msg.sender);
        lotteryBuyers.push(msg.sender);
        tickedId = Lottery.ticketsAmount;
        Lottery.ticketsAmount++;
        Lottery.potAmount += Lottery.ticketPrice;
        console.log("Current pot: ", Lottery.potAmount);
        console.log("Created ticket number: ", Lottery.ticketsAmount - 1);
        console.log("Current amount of tickets: ", Lottery.ticketsAmount);
        emit TicketBoughtEvent(msg.sender, tickedId, Lottery.ticketsAmount, Lottery.potAmount);
    }

    function withdrawFees() public isOwner {
        uint feesToWithdrew = address(this).balance - Lottery.potAmount;
        payable(msg.sender).transfer(feesToWithdrew);
        emit FeesWithdrewEvent(feesToWithdrew);
    }
    
    // ---------- EXCEPTION FLOWS: ----------

    // changes the overall price of each ticket, only doable by the Owner
    function changeTicketPrice(uint _ticketPrice) external isOwner isLotteryActive {
        uint oldTicketPrice = Lottery.ticketPrice;
        Lottery.ticketPrice = _ticketPrice;
        emit TicketPriceChangedEvent(oldTicketPrice, Lottery.ticketPrice);
    }

    // cancells a lottery and return the (funds - fees) to the adresses that sent them
    function cancelLottery() external isOwner isLotteryActive {
        uint oldLotteryBuyersLenght = lotteryBuyers.length;
        for (uint i=0; i<oldLotteryBuyersLenght; i++) {
            (bool sent, ) = lotteryBuyers[i].call{value: Lottery.ticketPrice}("");
            if(!sent) {
                notRefundedBuyers.push(lotteryBuyers[i]);
            }
            delete ticketToOwner[Lottery.ticketsAmount - 1 - i];
        }
        delete lotteryBuyers;
        Lottery.ticketsAmount = 0;
        Lottery.amountOfDays = 0;
        Lottery.potAmount = 0;
        Lottery.startingTimestamp = 0;
        emit LotteryCanceledEvent(oldLotteryBuyersLenght, notRefundedBuyers.length);
    }

    // if anything went wrong sending some founds in the "cancelLottery" function, we can retry the sending
    function retrySubmissionOfFounds() external isOwner {
        address [] memory tempNotRefundedBuyers;
        uint oldNotRefundedBuyersLenght = notRefundedBuyers.length;
        uint j=0;
        for (uint i=0; i<oldNotRefundedBuyersLenght; i++) {
            (bool sent, ) = notRefundedBuyers[i].call{value: Lottery.ticketPrice}("");
            if(!sent) {
                tempNotRefundedBuyers[j] = notRefundedBuyers[i];
                j++;
            }
        }
        notRefundedBuyers = tempNotRefundedBuyers;
        emit SubmissionOfFoundsRetriedEvent(oldNotRefundedBuyersLenght, notRefundedBuyers.length);
    }
}
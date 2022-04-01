pragma solidity ^0.4.2;

// TODO: Invite chain to incite people to invite people to get more money to bet

contract Lottery {
    // Address to send fees to
    address minter;
    uint balance;
    
    // Defines needed variables
    uint public ticketPrice;
    uint public roundDuration; // saved in seconds
    uint public nextWinnerPickedTime;
    
    // Initialized the ticketsInPool 0 on contract creation
    uint public ticketsInPool = 0;
    uint numberOfParticipants = 0;
    
    // Creates a strct that holds participants' information
    struct Participant {
        address participantAddress;
        uint numberOfTicketsOwned;
    }
    mapping (uint => Participant) participants;
    
    // Called upon creation of contract
    function Lottery (
        uint etherCostOfEachTicket, // in ethers
        uint lotteryRoundDurationInSeconds // in seconds
    ) {
        minter = msg.sender;
        ticketPrice = etherCostOfEachTicket * 1 ether;
        roundDuration = lotteryRoundDurationInSeconds * 1 seconds;
        nextWinnerPickedTime = now + roundDuration;
    }
    
    // This function without name is called anytime some sends funds to the contract
    function () {
        if(msg.value >= ticketPrice) {
            uint ticketsBought = msg.value*ticketPrice; // will round down = max tickets deposited amount can buy
            participants[numberOfParticipants] = Participant(msg.sender, ticketsBought);
            ticketsInPool += ticketsBought;
            numberOfParticipants += 1;
            // Send back or keep extra ethers? Keep all or send back a part of extra?   
        }
    }
    
    modifier afterPickWinnerTime() { 
        if (now >= nextWinnerPickedTime) _; 
    }
    
    function randomNumber(uint max) returns(uint randomNumber) {
        // Figure out a way to make this random number non-exploitable by miners
        uint pseudoRand = uint256(block.blockhash(block.number-5))**uint256(block.blockhash(block.number-2));
        return pseudoRand%(max+1); // will return a number between 0 and max
    }
    
    function pickRandomWinner() afterPickWinnerTime private {
        // first ticket will have id = 0 so last ticket with have id = ticketsInPool-1 so we get a max randomNumber = ticketsInPool-1
        uint winnerNumber = randomNumber(ticketsInPool-1);
        uint tickerNumberIndex = 0;
        for(uint i=0; i < numberOfParticipants; i++) {
            // by default tickerNumberIndex < winnerNumber is true so no need to check it to save resources otherwise previous participant would have won
            if(winnerNumber < tickerNumberIndex+participants[i].numberOfTicketsOwned) {
                // Winner found
                payWinner(participants[i].participantAddress);
            }
        }
    }
    
    function payWinner(address winnerAddress) private {
        if(!winnerAddress.send(ticketsInPool * ticketPrice)){
            // failed to pay fees
        }
        // decide fix it should withdrawl extra fees or just use them to pay people to participate in the lottery
    }
    
    function withdrawFees(uint totalFees) {
        if(minter == msg.sender && totalFees <= balance) {
            if(!minter.send(totalFees)){
                // failed to pay fees
            }   
        }
    }
    
    function resetForNextRound() private {
        ticketsInPool = 0;
        numberOfParticipants = 0;
    }
    
}

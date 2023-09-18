pragma solidity ^0.4.19; 

contract Lottery {
    
    /*  Constants   */
    uint constant fullTicketPrice = 8 finney ;
    uint constant halfTicketPrice = 4 finney ;
    uint constant quarterTicketPrice = 2 finney ;
    
    /*
    Number of random to be submitted when buying a new ticket.
    If callers submit less or more the call will be reverted.
    */
    uint constant numberOfRandoms = 3;
    /*
    Number of blocks until the round ends.
    There are two rounds, submission and reveal.
    */
    uint constant roundPeriod = 20000;
    /* 
    Second winner will get 1/secondWinnerCof of the relative price.
    */
    uint constant secondWinnerCof = 2;
    
    /* 
    Third winner will get 1/thirdWinnerCof of the relative price.
    */
    uint constant thirdWinnerCof = 4;
    
    
    uint collected_money_current; // Total collected money until current rounds reveal time
    uint collected_money_next; // Collected money at next rounds submission time
    
    /* 
    Users prizes will be stored in this mapping so that they can withdraw their 
    winnings any time they want to.
    */
    mapping(address=>uint) profits;

    /*
    approvedTickets is the mapping that keeps successfully revealed tickets according 
    to round number. Note thatonly 3 of the successfully revealed tickets can win 
    the prizes
    */
    mapping(uint => Ticket[]) approvedTickets;
    
    /*
    tikcekts is the array that keeps all the tickets submitted at submission time
    of corresponding round
    */
    mapping(uint => mapping(address => Ticket[])) tickets;

    /*
    isSubmissionTime is used to check if it is submission or reveal time.
    */
    bool isSubmissionTime; 
    
    /*
    submissionStartBlockNumber is used to determine if it is time to switch between 
    submission and reveal periods.
    */
    uint submissionStartBlockNumber;
    uint revealStartBlockNumber;

    /*
    initialBlockNumber is used to keep block number
    */
    uint initialBlockNumber;

    /*
    submission round number and reveal round number are used to keep track of round numbers
    */
    uint submissionRoundNumber;
    uint revealRoundNumber;
    
    int firstHash; // firstHash is the hash used to determine the first winner
    int secondHash; // secondHash is the hash used to determine the second winner
    int thirdHash; // thirdHash is the hash used to determine the third winner
    
    function Lottery () public {
        isSubmissionTime = true; // We start with the submission period.
        initialBlockNumber = block.number; // Let the current block be the initial block
        submissionStartBlockNumber = block.number; // Let the current block be the startBlock.
        revealStartBlockNumber = submissionStartBlockNumber + roundPeriod;
        submissionRoundNumber = 1;
        revealRoundNumber = 1;
    }

    struct Ticket{
        address buyersAddress;
        uint8 ticketCoeffecient; // 2 -> Full 4 -> Half 8-> Quarter
        bytes32[] hashes;
    }
    
    modifier noEthSent(){
        if (msg.value>0) {
            revert();
        }
        _;
    }
    
    modifier FullTicket() {
        if (msg.value < fullTicketPrice) {
            revert();
        }
        _;
    }
    
    modifier HalfTicket() {
        if (msg.value < halfTicketPrice) {
            revert();
        }
        _;
    }
    
    modifier QuarterTicket() {
        if (msg.value < quarterTicketPrice) {
            revert();
        }
        _;
    }
    
    // withdraw lets winners withdraw their winnings.
    // This method first subtracts the amount to be withdrawn from the account
    // so that DOA (recursive calls) are not dangerous for the contract. After 
    // subtracting the relevant amount the send call is executed. Note that if 
    // caller tries to withdraw more than his winnings it will be reverted.
    function withdraw(uint amount) public {
        if (profits[msg.sender] <= 0) revert();
        if (profits[msg.sender] >= amount) {
            profits[msg.sender] -= amount;
            if (!msg.sender.send(amount)) revert();
        }
    }
    
    function sendTheRemainingMoney(uint ticketPrice) private {
        if (msg.value > ticketPrice) {
            if (!msg.sender.send(msg.value-ticketPrice))  revert();
        }
    }    

    function compareArrays(bytes32[] _arr1, bytes32[] _arr2) private pure returns(bool retval){
        
        uint len_arr1 = _arr1.length;
        uint len_arr2 = _arr2.length;
        
        if(len_arr1 != len_arr2){
            return(false);
        }
        
        for(uint i = 0; i< len_arr1; i++){
            if(_arr1[i] != _arr2[i]){
                return(false);
            }
        }
        
        return(true);
    }

    function checkHashes(Ticket[] ticketsOfParticipant,bytes32[] givenHashes) private pure returns(int){
        int len = int(ticketsOfParticipant.length);
        for(int i = 0; i< len ; i++){
            if (compareArrays(ticketsOfParticipant[uint(i)].hashes, givenHashes)){
                return i;
            }
        }
        return -1;
    }
    
    function isEndOfReveal() private view returns(bool){
        return block.number >= revealStartBlockNumber + roundPeriod;
    }
    
    function isEndOfSubmission() private view returns (bool){
        return block.number >= submissionStartBlockNumber + roundPeriod;
    }

    function canSubmit() private view returns (bool) {
        return (block.number >= submissionStartBlockNumber) && (block.number < (submissionStartBlockNumber + roundPeriod));
    }

    function canReveal() private view returns (bool) {
        return (block.number >= revealStartBlockNumber) && (block.number < (revealStartBlockNumber + roundPeriod));
    }
    
    function removeTicket(uint _roundNumber, address _ticketOwner, int _index) private{
        int len = int(tickets[_roundNumber][_ticketOwner].length);
        if(_index >= len){
            revert();
        }else{
            tickets[_roundNumber][_ticketOwner][uint(_index)] = tickets[_roundNumber][_ticketOwner][uint(len-1)];
            delete tickets[_roundNumber][_ticketOwner][uint(len-1)];
        }
    }
    
    function updateRandomHashes(int[] numbers) private {
        firstHash ^= numbers[0];
        secondHash ^= numbers[1];
        thirdHash ^= numbers[2];
    }
    
    function findWinnersAndGivePrizes(uint _roundNumber) private returns(bool){
        uint numberOfParticipants = approvedTickets[_roundNumber].length;
        if (numberOfParticipants < 3){
            return false;
        }
        // Take the mod with the numberOfParticipants so that it is guaranteed
        // that there will be a winner.
        uint firstWinnerIndex = uint(firstHash)%numberOfParticipants;
        uint secondWinnerIndex = uint(secondHash)%numberOfParticipants;
        uint thirdWinnerIndex = uint(thirdHash)%numberOfParticipants;

        // Make sure winners are different indexes.
        while((firstWinnerIndex == secondWinnerIndex)||(firstWinnerIndex == thirdWinnerIndex)||(secondWinnerIndex == thirdWinnerIndex)){
            if(firstWinnerIndex == secondWinnerIndex){
                firstWinnerIndex = (firstWinnerIndex + 1) % numberOfParticipants;
            }

            if(firstWinnerIndex == thirdWinnerIndex){
                firstWinnerIndex = (firstWinnerIndex + 1) % numberOfParticipants;
            }

            if(secondWinnerIndex == thirdWinnerIndex){
                secondWinnerIndex = (secondWinnerIndex + 1) % numberOfParticipants;
            }
        }
         
        // Calculate the prizes based on the position and ticket type.
        uint firstPrize = collected_money_current/approvedTickets[_roundNumber][firstWinnerIndex].ticketCoeffecient; 
        uint secondPrize = collected_money_current/approvedTickets[_roundNumber][secondWinnerIndex].ticketCoeffecient/secondWinnerCof;
        uint thirdPrize = collected_money_current/approvedTickets[_roundNumber][thirdWinnerIndex].ticketCoeffecient/thirdWinnerCof;
        
        // Store the profits so that later on winners can withdraw them.
        profits[approvedTickets[_roundNumber][firstWinnerIndex].buyersAddress] += firstPrize;
        profits[approvedTickets[_roundNumber][secondWinnerIndex].buyersAddress] += secondPrize ;
        profits[approvedTickets[_roundNumber][thirdWinnerIndex].buyersAddress] += thirdPrize ;
        
        // Update the collected_money.
        collected_money_current -= firstPrize + secondPrize + thirdPrize;
        
        return true; 
    }
    
    function reveal(int[] numbers) public noEthSent {
        // Check if it is time to find winners. If so switch to the submission period.
        if (isEndOfReveal()){
            // Give the prizes.
            findWinnersAndGivePrizes(revealRoundNumber);
            revealStartBlockNumber = revealStartBlockNumber + roundPeriod;
            revealRoundNumber = revealRoundNumber + 1;
        }
        
        // Check if it is reveal time or not
        require(canReveal());

        // Check if numbers are exactly 'numberOfRandoms'. Otherwise revert.
        if (!hasExactlyXElementsIntArray(numberOfRandoms,numbers)) revert();
        bytes32[] memory givenHashes = new bytes32[](numberOfRandoms);
        // Calculate the hashes with the given number and the senders address
        for (uint i = 0 ; i < numbers.length;i++){
            givenHashes[i]=(keccak256(numbers[i],msg.sender));
        }
        
        // Check if the submission and reveal hashes are matched. Otherwise revert.
        int index = checkHashes(tickets[revealRoundNumber][msg.sender],givenHashes);
        if (index == -1) revert();
        
        // If submission and reveal hashes are matched, the ticket can join the lottery
        approvedTickets[revealRoundNumber].push(Ticket(tickets[revealRoundNumber][msg.sender][uint(index)].buyersAddress, tickets[revealRoundNumber][msg.sender][uint(index)].ticketCoeffecient, tickets[revealRoundNumber][msg.sender][uint(index)].hashes));
        
        // Remove from candidate ticket list
        removeTicket(revealRoundNumber, msg.sender, index);
        
        // Update the hashes to determine the winners.
        updateRandomHashes(numbers);

    }
    function hasExactlyXElements(uint x,bytes32[] hashArray) private pure returns(bool){
        return hashArray.length == x;
    }
    
    function hasExactlyXElementsIntArray(uint x,int[] intArray) private pure returns(bool){
        return intArray.length == x;
    }
    function buyFullTicket(bytes32[] hashArray) public FullTicket /*canSubmit*/ payable returns (bool bought){
        if(isEndOfSubmission()){
            collected_money_current += collected_money_next;
            collected_money_next = 0;
            submissionStartBlockNumber = submissionStartBlockNumber + roundPeriod;
            submissionRoundNumber = submissionRoundNumber + 1;
        }

        require(canSubmit());

        buyTicket(fullTicketPrice,hashArray,2);
        return true;
    }
    
    function buyHalfTicket(bytes32[] hashArray) public HalfTicket /*canSubmit*/ payable returns (bool bought){
        if(isEndOfSubmission()){
            collected_money_current += collected_money_next;
            collected_money_next = 0;
            submissionStartBlockNumber = submissionStartBlockNumber + roundPeriod;
            submissionRoundNumber = submissionRoundNumber + 1;
        }

        require(canSubmit());

        buyTicket(halfTicketPrice,hashArray,4);
        return true;
    }
    
    function buyQuarterTicket(bytes32[] hashArray) public QuarterTicket /*canSubmit*/ payable returns (bool bought){
        if(isEndOfSubmission()){
            collected_money_current += collected_money_next;
            collected_money_next = 0;
            submissionStartBlockNumber = submissionStartBlockNumber + roundPeriod;
            submissionRoundNumber = submissionRoundNumber + 1;
        }

        require(canSubmit());

        buyTicket(quarterTicketPrice,hashArray,8);
        return true;
    }
    
    function buyTicket(uint ticketPrice,bytes32[] hashArray,uint8 ticketCoefficient) private {
        // Check if there are exactly 'numberOfRandoms' hashes. Otherwise revert.
        if (!hasExactlyXElements(numberOfRandoms,hashArray)) revert();
        // Record the hashes of the sender to verify later
        // Add the caller to the participants
        tickets[submissionRoundNumber][msg.sender].push(Ticket(msg.sender, ticketCoefficient, hashArray));
        collected_money_next += ticketPrice;
        // Send the excessive amount
        sendTheRemainingMoney(ticketPrice);

    }

    function getCollectedMoney() public view returns(uint){
        return collected_money_current;
    }
    
    function getBlockNumber() public view returns(uint){
        return block.number;
    }
    
    function getRound() public view returns(uint){
        return block.number;
    }
    function getHash(address x) public pure returns(bytes32){
        return keccak256(int(9),x);
    }

    function getProfit() public view returns(uint){
        return profits[msg.sender];
    }

    function getInitialBlockNumber() public view returns(uint){
        return initialBlockNumber;
    }
}

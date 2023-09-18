pragma solidity ^0.4.10;

contract Lottery {
    
    struct TicketHolder {
        address _holderAddress;
        uint _numTickets;
    }

    //----------Variables------------
    // Mapping of tickets issued to each address
    mapping (address => uint) public ticketHolders;
    address[] public holders;

    // Array of previous winners.
    // TODO: Only hold last 10 winners
    address[] public prevWinners;

    // Winner of the current lottery
    address public winner;

    // Total number of tickets issued
    uint public ticketsIssued;

    // Total balance of the smart contract
    uint public contractBalance;

    // When the lottery started
    uint public lotteryStart;

    // Duration the lottery will be active for
    uint public lotteryDuration;

    // Flag that the lottery is now over
    bool public lotteryEnded;

    // Total Eth that has been won from users using the contract
    uint public totalEthWon;

    //----------Events---------------
    // Event for when tickets are bought
    event TicketsBought(address indexed _from, uint _quantity);

    // Event for declaring the winner
    event AwardWinnings(address _to, uint _winnings);

    // Event for lottery reset
    event ResetLottery();

    //---------Modifiers---------------

    // Checks if still in lottery contribution period
    modifier lotteryOngoing() {
        require(now < lotteryStart + lotteryDuration);
        _;
    }

    // Checks if lottery has finished
    modifier lotteryFinished() {
        require(now > lotteryStart + lotteryDuration);
        _;
    }

    //---------Functions----------------
    
    //Create the lottery, each one lasts for 24 hours
    function Lottery() {
        ticketsIssued = 0;
        lotteryStart = now;
        lotteryDuration = 24 hours;
    }

    // Fallback function calls buyTickets
    function () payable {
        buyTickets();
    }
    // Award users tickets for eth, 1 finney = 1 ticket
    function buyTickets() payable lotteryOngoing returns (bool success) {
        ticketHolders[msg.sender] = msg.value / (10**15);
        ticketsIssued += ticketHolders[msg.sender];
        holders.push(msg.sender);
        contractBalance += msg.value;
        TicketsBought(msg.sender, ticketHolders[msg.sender]);
        return true;
    }

    // After winners have been declared and awarded, clear the arrays and reset the balances
    function resetLottery() lotteryFinished returns (bool success) {
        lotteryEnded = false;
        lotteryStart = now;
        lotteryDuration = 24 hours;
        ResetLottery();
        return true;
    }

    // This will distribute the correct winnings to each winner
    function awardWinnings(address _winner) internal lotteryOngoing returns (bool success) {
        _winner.transfer(contractBalance);
        AwardWinnings(_winner, contractBalance);
        contractBalance = 0;
        resetLottery();
        return true;
    }

    //Generate the winners by random using tickets bought as weight
    function generateWinners() lotteryFinished returns (uint winningTicket) {

        //Need to make this truly random - This is temp solution for testing
        uint randNum = uint(block.blockhash(block.number - 1)) % ticketsIssued + 1;
        winner = holders[randNum];
        prevWinners.push(winner);
        awardWinnings(winner);
        return randNum;
    }

    function getTicketBalance(address _account) constant returns (uint balance) {
        return ticketHolders[_account];
    }

    function getBalance() constant returns (uint) {
        return this.balance;
    }
}
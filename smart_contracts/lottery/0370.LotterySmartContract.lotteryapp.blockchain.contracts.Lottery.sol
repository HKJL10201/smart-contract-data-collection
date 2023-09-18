// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TL.sol";
import "./Ticket.sol";

contract Lottery {

    // Payment

    // Turkish Lira token for the payment system
    TL public token = new TL(10000);
    // Balance of each user
    mapping(address => uint256) public balances;
    // Total money collected for each lottery
    mapping(uint256 => uint256) public totalSupplies;

    // Tickets

    // Number of tickets sold since deployment
    uint256 public ticketCounter = 0;
    // Accesses ticket instances from ticket numbers
    mapping(uint256 => Ticket) public ticketsFromNo;
    // Tickets owned by each user in each lottery
    mapping(uint256 => mapping(address => Ticket[])) public ticketsFromLottery;

    // Time

    // Deployment time of the lottery contract
    uint256 public start;
    // Bool for each lottery, showing whether the winners were already chosen or not
    mapping(uint256 => uint8) public isSelected;

    // Random numbers

    // Random numbers that are revealed in reveal phase for each lottery
    mapping(uint256 => uint256[]) public randomNumbers;
    // Maps random numbers to ticket numbers of the associated tickets for each lottery
    mapping(uint => mapping(uint256 => uint256)) public ticketsFromRandoms;
    // Ticket numbers of winning tickets for each lottery, 'i'th element is 'i'th winner
    mapping(uint => uint256[]) public winningTickets;

    // Logs total lottery money
    event lotMoney(uint amnt);

    /**
    * @dev Checks if the lottery, which the ticket with given ticket number has been bought, has ended
    */
    modifier lotteryFinished(uint ticket_no) {
        require(getLotteryNoBySec(block.timestamp) > ticketsFromNo[ticket_no].getLotteryNo(), "Lottery is not finished yet");
        _;
    }

    /**
    * @dev Checks if the ticket with given ticket number has been created
    */
    modifier ticketExists(uint ticket_no) {
        require(ticket_no < ticketCounter, "Ticket does not exist");
        _;
    }

    /**
    * @dev Checks if the lgiven lottery number is noun-negative
    */
    modifier lotteryExists(uint lottery_no) {
        require(lottery_no >= 0, "Lottery number can not be negative");
        _;
    }

    /**
    * @dev Constructor of the Lottery contract
    */
    constructor() {
        start = block.timestamp;
    }

    /**
    * @dev Fallback function
    */
    fallback() external {
        revert();
    }

    /**
    * @dev Returns balance of the caller in the lottery system
    */
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /**
    * @dev Deposits the given amount of TL into the lottery system for the caller
    * @param amnt Amount of TL to deposit
    * Requirements:
    * - The caller must have at least the given amount of TL
    */
    function depositTL(uint amnt) public {
        if (token.transfer(address(this), amnt)) {
            balances[msg.sender] += amnt;
        }
    }

    /**
    * @dev Withdraws the given amount of TL from the lottery system to the caller
    * @param amnt Amount of TL to withdraw
    * Requirements:
    * - The caller must have at least the given amount of TL in the lottery system
    */
    function withdrawTL(uint amnt) public {
        require(amnt <= balances[msg.sender], "Not enough TL in the account");
        if (token.send(address(this), msg.sender, amnt)) {
            balances[msg.sender] -= amnt;
        }
    }

    /**
    * @dev Creates a new ticket for the caller using the hash of the private random number of the caller
    * @param hash_rnd_number Hash of the private random number of the caller
    * Requirements:
    * - The lottery must be in the purchase phase
    * - The caller must have at least the price of the ticket in the lottery system
    */
    function buyTicket(bytes32 hash_rnd_number) public {
        uint lotteryNo = getLotteryNoBySec(block.timestamp);
        require(block.timestamp - start - (1 weeks) * lotteryNo < 4 days, "Lottery is not in purchase phase");
        require(balances[msg.sender] >= 10, "Not enough TL in the account");
        balances[msg.sender] -= 10;
        Ticket curTicket = new Ticket(ticketCounter, msg.sender, hash_rnd_number, lotteryNo);
        ticketsFromNo[ticketCounter] = curTicket;
        ticketsFromLottery[lotteryNo][msg.sender].push(curTicket);
        ticketCounter += 1;
        totalSupplies[lotteryNo] += 10;
    }

    /**
    * @dev Refunds half of the ticket price to the caller if the ticket has not been revealed in the correct reveal phase
    * @param ticket_no Ticket number of the ticket to get refund
    * Requirements:
    * - The ticket number must be valid
    * - The lottery which the ticket has been bought must be finished
    */
    function collectTicketRefund(uint ticket_no) public lotteryFinished(ticket_no) ticketExists(ticket_no) {
        require(ticketsFromNo[ticket_no].status() <= 1, "Ticket is not cancelled");
        Ticket refunded = ticketsFromNo[ticket_no];
        balances[refunded.getOwner()] += 5;
    }

    /**
    * @dev Reveals the random number of the ticket with the given ticket number
    * If the hash associated with the ticket corresponds to the given random number, then the ticket is marked as revealed.
    * If not, the ticket is marked as cancelled.
    * @param ticketno Ticket number of the ticket to reveal
    * @param rnd_number Random number to reveal
    * Requirements:
    * - The ticket number must be valid
    * - The lottery must be in the reveal phase
    * - The ticket must be bought in the purchase phase of the current lottery
    * - The ticket must not be revealed or cancelled already
    */
    function revealRndNumber(uint ticketno, uint rnd_number) public ticketExists(ticketno) {
        Ticket ticket = ticketsFromNo[ticketno];
        uint lotteryNo = ticket.getLotteryNo();
        require(getLotteryNoBySec(block.timestamp) == lotteryNo, "Ticket is from other lottery");
        require(block.timestamp - (1 weeks) * lotteryNo >= 4 days, "Lottery is not in reveal phase");
        require(ticket.status() == 0, "Ticket is already revealed or cancelled");
        if (ticket.getHash_rnd_number() == keccak256(abi.encodePacked(rnd_number))) {
            randomNumbers[lotteryNo].push(rnd_number);
            ticketsFromRandoms[lotteryNo][rnd_number] = ticketno;
            ticket.setStatus(3);
        } else {
            ticket.setStatus(1);
        }
    }

    /**
    * @dev Returns the last bought ticket by the caller in the given lottery
    * @param lottery_no Lottery number of the lottery to look up the tickets
    * @return ticket_no Ticket number of the last bought ticket by the caller in the given lottery
    * @return status Status of the last bought ticket by the caller in the given lottery
    * Requirements:
    * - The lottery number must be non-negative
    * - The caller must have bought at least one ticket in the given lottery
    */
    function getLastOwnedTicketNo(uint lottery_no) public view lotteryExists(lottery_no) returns(uint, uint8 status) {
        uint i = ticketsFromLottery[lottery_no][msg.sender].length - 1;
        require(i >= 0, "No ticket bought");
        return (ticketsFromLottery[lottery_no][msg.sender][i].getTicketNo(),
            ticketsFromLottery[lottery_no][msg.sender][i].status());
    }

    /**
    * @dev Returns the 'i'th bought ticket by the caller in the given lottery
    * @param i The index of the ticket to look up
    * @param lottery_no Lottery number of the lottery to look up the tickets
    * @return ticket_no Ticket number of the last bought ticket by the caller in the given lottery
    * @return status Status of the last bought ticket by the caller in the given lottery
    * Requirements:
    * - The lottery number must be non-negative
    * - The index should bemore than 1 and less than number of bought tickets by teh caller in the given lottery
    */
    function getIthOwnedTicketNo(uint i, uint lottery_no) public view lotteryExists(lottery_no) returns(uint, uint8 status) {
        require(i > 0 && i <= ticketsFromLottery[lottery_no][msg.sender].length, "Ticket index out of bounds");
        return (ticketsFromLottery[lottery_no][msg.sender][i - 1].getTicketNo(),
            ticketsFromLottery[lottery_no][msg.sender][i - 1].status());
    }

    /**
    * @dev Returns the ceiling of the binary logarithm of the given number
    * @param x The number to get the logarithm of
    * @return n The logarithm
    * Requirements:
    * - The number must be positive
    */
    function ceilLog2(uint x) public pure returns (uint) {
        x -= 1;
        uint n = 0;
        if (x >= 2**128) { x >>= 128; n += 128; }
        if (x >= 2**64) { x >>= 64; n += 64; }
        if (x >= 2**32) { x >>= 32; n += 32; }
        if (x >= 2**16) { x >>= 16; n += 16; }
        if (x >= 2**8) { x >>= 8; n += 8; }
        if (x >= 2**4) { x >>= 4; n += 4; }
        if (x >= 2**2) { x >>= 2; n += 2; }
        if (x >= 2**1) { n += 1; }
        n += 1;
        return n;
    }

    /**
    * @dev Selects the winner tickets for the given lottery
    * It uses randomNumbers array to select random indexes, then gets the random numbers at these indexes. For each of the
    * random number selected, the ticket associated with it is accessed by ticketsFromRandoms mapping and the ticet number
    * for this ticket is put to winningTickets array. The index 'i' in winningTickets array means that the ticket with the
    * ticket number at that index is the '(i + 1)'th winner of the lottery.
    * The first random number index is selected by taking xor of all the random numbers available and taking the mod of the
    * result with the length of the randomNumbers array. The rest of the random number indexes are selected by taking the
    * mod of the previous random number with the number of winners to be selected from now on.
    * @param lotteryNo Lottery number of the lottery to select the winners
    */
    function selectWinners(uint lotteryNo) private {
        emit lotMoney(getTotalLotteryMoneyCollected(lotteryNo));

        uint nofWinners = ceilLog2(getTotalLotteryMoneyCollected(lotteryNo)) + 1;
        if (nofWinners == 0) {
            return;
        }
        uint n = randomNumbers[lotteryNo].length;
        uint xor = 0;
        for (uint i = 0; i < n; i++) {
            xor ^= randomNumbers[lotteryNo][i];
        }
        uint index = xor % n;
       
        winningTickets[lotteryNo].push(ticketsFromRandoms[lotteryNo][randomNumbers[lotteryNo][index]]);
        uint loopCount = nofWinners < n ? nofWinners: n;
        for (uint i = 0; i < loopCount - 1; i++) {
            
            (randomNumbers[lotteryNo][index], randomNumbers[lotteryNo][n - 1 - i]) =
                (randomNumbers[lotteryNo][n - 1 - i], randomNumbers[lotteryNo][index]);
            index = randomNumbers[lotteryNo][n - 1 - i] % (n - 1 - i);
            winningTickets[lotteryNo].push(ticketsFromRandoms[lotteryNo][randomNumbers[lotteryNo][index]]);
        }
    }

    /**
    * @dev Ensures that the winners are selected for the given lottery
    * @param lottery_no Lottery number of the lottery to select the winners for
    */
    function ensureResults(uint lottery_no) private {
        if (isSelected[lottery_no] == 0) {
            selectWinners(lottery_no);
            isSelected[lottery_no] = 1;
        }
    }

    /**
    * @dev Calculates the 'i'th winner's prize for the given money supply
    * @param i The index of the prize winner
    * @param totalSupply The total money supply
    * @return amount The prize amount
    */
    function calculatePrize(uint i, uint256 totalSupply) public pure returns (uint amount) { 
        return (totalSupply / (2**i)) + ((totalSupply / (2**(i - 1))) % 2);
    }

    /**
    * @dev Returns the prize the ticket with the given ticket number has won
    * @param ticket_no The ticket number of the ticket to get the prize for
    * @return amount The prize amount
    * Requirements:
    * - The ticket number must be valid
    * - The lottery which the ticket has been bought must have ended
    */
    function checkIfTicketWon(uint ticket_no) public ticketExists(ticket_no) lotteryFinished(ticket_no) returns (uint amount) {
        Ticket ticket = ticketsFromNo[ticket_no];
        uint lotteryNo = ticket.getLotteryNo();
        ensureResults(lotteryNo);
        for (uint i = 0; i < winningTickets[lotteryNo].length; i++) {
            if (winningTickets[lotteryNo][i] == ticket_no) {
                return calculatePrize(i + 1, totalSupplies[lotteryNo]);
            }
        }
        return 0;
    }

    /**
    * @dev Gives the ticket owner the prize for the ticket with the given ticket number
    * @param ticket_no The ticket number of the ticket to get the prize for
    * Requirements:
    * - The ticket number must be valid
    * - The lottery which the ticket has been bought must have ended
    * - The prize for the ticket must not have been given yet
    */
    function collectTicketPrize(uint ticket_no) public ticketExists(ticket_no) lotteryFinished(ticket_no) {
        require(ticketsFromNo[ticket_no].status() != 4, "Ticket prize has already been collected");
        require(ticketsFromNo[ticket_no].status() != 1, "Ticket has been cancelled");
        ensureResults(ticketsFromNo[ticket_no].getLotteryNo());
        uint256 amount = checkIfTicketWon(ticket_no);
        ticketsFromNo[ticket_no].setStatus(4);
        balances[ticketsFromNo[ticket_no].getOwner()] += amount;
    }

    /**
    * @dev Returns the 'i'th winner ticket and the prize for the given lottery
    * @param i The index of the winner tickets to look up
    * @param lottery_no The lottery number of the lottery
    * @return ticket_no The ticket number of the 'i'th winner ticket
    * @return amount The prize amount
    * Requirements:
    * - The lottery number must be non-negative
    * - The lottery must have ended
    * - The index must be positive and less than or eqaul to the number of winners
    */
    function getIthWinningTicket(uint i, uint lottery_no) public lotteryExists(lottery_no) returns (uint ticket_no, uint amount) {
        require(lottery_no <= getLotteryNoBySec(block.timestamp), "Lottery is not finished yet");
        require(i > 0 && i <= ceilLog2(getTotalLotteryMoneyCollected(lottery_no)) + 1, "Ticket index out of bounds or ticket has not won");
        ensureResults(lottery_no);
        return (winningTickets[lottery_no][i - 1], checkIfTicketWon(winningTickets[lottery_no][i - 1]));
    }
    
    /**
    * @dev Returns the lottery number for the given time in weeks
    * @param unixtimeinweek The time in weeks
    * @return lottery_no The lottery number
    */
    function getLotteryNo(uint unixtimeinweek) public view returns (uint lottery_no) {
        return unixtimeinweek - (start / (1 weeks));
    }

    /**
    * @dev Returns the lottery number for the given time in seconds
    * @param unixtimeinsec The time in seconds
    * @return lottery_no The lottery number
    */
    function getLotteryNoBySec(uint unixtimeinsec) public view returns (uint lottery_no) {
        return (unixtimeinsec - start) / (1 weeks);
    }

    /**
    * @dev Returns the total money collected for the given lottery
    * @param lottery_no The lottery number
    * @return amount The total money collected
    * Requirements:
    * - The lottery number must be non-negative
    */
    function getTotalLotteryMoneyCollected(uint lottery_no) public view lotteryExists(lottery_no) returns (uint amount) {
        return totalSupplies[lottery_no];
    }

}
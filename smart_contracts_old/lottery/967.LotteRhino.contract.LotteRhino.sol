// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LotteRhino {

    // ###############
    // # CONSTRUCTOR #
    // ###############

    /*
     * Contract constructor
     * --------------------
     * Construct the contract
     *
     * @param string memory sentence_
              Password alike phrase to protect the contract.
     * @param uint256 _lotteryRoundInterval_
              Interval of the lottery rounds in seconds.
     * @param uint256 ticketPeriod_
              Amount of time in seconds while buying a ticket is permitted.
     * @param uint256 firstlotteryRoundTime_
              Timestamp (in seconds) of the begin of the first round.
     * @param uint256 ticketPrice_
              Price of a ticket in the smallest unit (like wei).
     */
    constructor(string memory sentence_, uint256 lotteryRoundInterval_,
                uint256 ticketPeriod_, uint256 firstlotteryRoundTime_,
                uint256 ticketPrice_) payable {

        rootUser = payable(msg.sender);
        rootKey = keccak256(abi.encodePacked(sentence_));
        lotteryRoundInterval = lotteryRoundInterval_;
        ticketPeriod = ticketPeriod_;
        firstlotteryRoundTime = firstlotteryRoundTime_;
        ticketPrice = ticketPrice_;
        jackpot = 0;
        ticketCount = 0;
        address[] memory addresses;
        LotteryRound memory round = LotteryRound(ROUND_OPEN,
                                                 firstlotteryRoundTime,
                                                 0,
                                                 0,
                                                 blockhash(block.number),
                                                 0,
                                                 0,
                                                 0,
                                                 addresses);
        lotteryRounds.push(round);

    }

    // ##################
    // # USER FUNCTIONS #
    // ##################

    /*
     * Create a ticket
     * ---------------
     * Perform a ticket sell for the user themself
     *
     * @param uint templateId_
     *        ID of the picture template to use for the ticket.
     * @param string calldata uniqueMessage_
     *        A unique sentence to display on the ticket.
     */
    function buyTicket(uint templateId_,
                       string calldata uniqueMessage_)
                       onlyAvailableUser(msg.sender) onlyOpenRound()
                       external payable {

        require(msg.value + users[msg.sender].balance >= ticketPrice,
                'Not enough fund to buy a ticket.');
        _createTicket(msg.sender, templateId_, uniqueMessage_);

    }

    /*
     * Create a ticket
     * ---------------
     * Perform a ticket sell for a recipient selected by the user
     *
     * @param address for_
     *        Address of the recipient of the ticket.
     * @param uint templateId_
     *        ID of the picture template to use for the ticket.
     * @param string calldata uniqueMessage_
     *        A unique sentence to display on the ticket.
     */
    function buyTicketFor(address for_, uint templateId_,
                          string calldata uniqueMessage_)
                          onlyAvailableUser(msg.sender) onlyOpenRound()
                          external payable {

        require(msg.value + users[msg.sender].balance >= ticketPrice,
                'Not enough fund to buy a ticket.');
        _createTicket(for_, templateId_, uniqueMessage_);

    }


    /*
     * Get user balance
     * ----------------
     * Return the amount of the in-contract balance of the user
     *
     * @return uint256
     *         The balance of the user in the smallest unit (like wei).
     */
    function getBalance() external view returns (uint256) {

        return users[msg.sender].balance;

    }

    /*
     * Get ticket information
     * ----------------------
     * Return information about all tickets of the user
     *
     * @return TicketInfo[] memory
     *         List of all tickets of the user.
     */
    function getTicketList() external view returns (TicketInfo[] memory) {

        uint counter = 0;
        for (uint256 i=0; i < ticketCount; i++)
            if (allTickets[i].owner == msg.sender)
                counter++;
        TicketInfo[] memory result = new TicketInfo[](counter);
        if (counter > 0) {
            counter = 0;
            for (uint256 i=0; i < ticketCount; i++)
                if (allTickets[i].owner == msg.sender) {
                    result[counter] = TicketInfo(i,
                                                 ticketsToRound[i],
                                                 allTickets[i]);
                    counter++;
                }
        }
        return result;

    }

    /*
     * Get UI data
     * -----------
     * Return the latest data to display on the UI
     *
     * @return UIRecord memory
     *         Fresh data to display on the UI.
     */
    function getUIRecord() external view returns (UIRecord memory) {

        uint256 prizePool = _percentageOf(90,
                                          lotteryRounds[lotteryRounds.length - 1]
                                          .ticketCount * ticketPrice);
        address[] memory winners;
        uint256 won = 0;
        if (lotteryRounds.length > 2) {
            winners = lotteryRounds[lotteryRounds.length - 2].winners;
            won = _getPot(lotteryRounds.length - 2)
                  / lotteryRounds[lotteryRounds.length - 2].ticketCount;
        } else winners = new address[](0);
        uint256 lastwonJackpotTime = 0;
        uint256 lastwonJackpotAmount = 0;
        address lastJackpotAddress;
        if (jackpots.length > 0) {
            lastwonJackpotTime = lotteryRounds[jackpots[jackpots.length - 1]
                                 .roundID].drawTime;
            lastwonJackpotAmount = jackpots[jackpots.length - 1].amount;
            lastJackpotAddress = jackpots[jackpots.length - 1].winner;
        }
        return UIRecord(lotteryRounds.length - 1,
                        lotteryRounds[lotteryRounds.length - 1].state,
                        lotteryRounds[lotteryRounds.length - 1].beginTime
                        + lotteryRoundInterval,
                        lotteryRounds[lotteryRounds.length - 1].beginTime
                        + ticketPeriod,
                        prizePool,
                        winners,
                        won,
                        jackpot,
                        lastwonJackpotTime,
                        lastwonJackpotAmount,
                        lastJackpotAddress);

    }

    /*
     * Initiate draw process
     * ---------------------
     * Perform the whole draw process of the actual round and create new round
     *
     */
    function initiateDraw() onlyIfDrawAvailable() external {

        bytes32 seed = _getSeed();
        uint256 pot = _getPot(lotteryRounds.length - 1);
        uint256 potUnit;
        uint winnerCount;
        if (lotteryRounds[lotteryRounds.length - 1].ticketCount > 100) {
            winnerCount = _getRandomInInterval(seed, 10, 20);
            potUnit = pot / 20;
        } else {
            winnerCount = 1;
            potUnit = pot / 3;
        }
        LotteryTicket[] memory tickets =
                                _getTicketsForRound(lotteryRounds.length - 1);
        address[] memory winners = new address[](winnerCount);
        uint counter = 0;
        uint position;
        bool notFound;
        uint maxTicketID = lotteryRounds[lotteryRounds.length - 1]
                           .ticketCount - 1;
        address newWinner;
        while (counter < winnerCount) {
            position = _getRandomInInterval(seed, 0, maxTicketID);
            newWinner = tickets[position].owner;
            notFound = true;
            for (uint i=0; i < counter; i++)
                if (newWinner == winners[i]) {
                    notFound = false;
                    break;
                }
            if (notFound) {
                winners[counter] = newWinner;
                counter++;
                pot -= potUnit;
                _transferPrize(newWinner, potUnit);
            }
        }
        if (_getRandomInInterval(seed, 0, 99) == 99) {
            bool noWinner = true;
            while (noWinner) {
                position = _getRandomInInterval(seed, 0, maxTicketID);
                newWinner = tickets[position].owner;
                notFound = true;
                for (uint i=0; i < counter; i++)
                    if (newWinner == winners[i]) {
                        notFound = false;
                        break;
                    }
                if (notFound) {
                    noWinner = false;
                    uint256 jackpotToTransfer = jackpot;
                    jackpot = 0;
                    jackpots.push(JackpotRecord(lotteryRounds.length - 1,
                                                newWinner,
                                                jackpotToTransfer));
                    _transferPrize(newWinner, jackpotToTransfer);
                }
            }
        }
        jackpot += pot;
        _createRound();

    }

    /*
     * Withdraw user in-contract balance
     * ---------------------------------
     * Send the user's in-contract balance to the user's own account
     */
    function withdraw() onlyAvailableUser(msg.sender) external {

        require(users[msg.sender].balance > 0, 'This action requires balance.');
        address payable to = payable(msg.sender);
        uint256 amount = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        bool result = to.send(amount);
        require(result, 'Failed to withdraw.');

    }


    // ###################
    // # ADMIN FUNCTIONS #
    // ###################

    /*
     * Add NFT lottery ticket template
     * -------------------------------
     * Place new image template into the lottery ticket templates array
     *
     * @param string calldata sentence_
     *        A sentence to ensure admin call.
     * @param bytes calldata content_
     *        Binary form of the NFT image.
     */
    function addTicketTemplate(string calldata sentence_,
                               bytes calldata content_)
                               onlyAdmin(sentence_)
                               external {

        lotteryTicketTemplates.push(content_);

    }

    /*
     * Close the acutal round
     * ----------------------
     * Performs emergency close action on the last round if draw ran out of gas
     */
    function closeRound(string calldata sentence_)onlyAdmin(sentence_)
                        external {

        require(lotteryRounds[lotteryRounds.length - 1].state
                == ROUND_UNDER_DRAW,
                'Emergency close not reasonable');
        lotteryRounds[lotteryRounds.length - 1].state = ROUND_FINISHED;
        _createRound();

    }

    /*
     * Flush the contract
     * ------------------
     * Flush the amount of the unit content of the contract to the root user
     */
    function flush(string calldata sentence_) onlyAdmin(sentence_) external {

        address payable to = payable(msg.sender);
        bool result = to.send(address(this).balance);
        require(result, 'Failed to flush.');

    }

    /*
     * Get contract balance
     * --------------------
     * Get the actual balance of the contract
     *
     * @param string calldata sentence_
     *        A sentence to ensure admin call.
     *
     * @return uint256
     *         The balance of the contract in the smallest unit (like wei).
     */
    function getContractBalance(string calldata sentence_)
                                onlyAdmin(sentence_)
                                external view returns (uint256) {

        return address(this).balance;

    }

    // ######################
    // # INTERNAL FUNCTIONS #
    // ######################

    /*
     * Create a new lottery round
     * --------------------------
     * Perform the creation process of a new lottery round
     */
    function _createRound() internal {

        address[] memory addresses;

        lotteryRounds.push(LotteryRound(ROUND_OPEN,
                                        lotteryRounds[lotteryRounds
                                        .length - 1].beginTime
                                        + lotteryRoundInterval,
                                        0,
                                        0,
                                        blockhash(block.number),
                                        0,
                                        0,
                                        0,
                                        addresses));

    }

    /*
     * Create a ticket
     * ---------------
     * Perform a ticket sell for an address
     *
     * @param address for_
     *        Address of the recipient of the ticket.
     * @param uint templateId_
     *        ID of the picture template to use for the ticket.
     * @param string calldata uniqueMessage_
     *        A unique sentence to display on the ticket.
     *
     * @return UIRecord memory
     *         Fresh data to display on the UI.
     */
    function _createTicket(address for_, uint templateId_,
                           string calldata uniqueMessage_) internal {

        uint256 thisValue = msg.value;
        if (thisValue >= ticketPrice) thisValue -= ticketPrice;
        else if (users[msg.sender].balance >= ticketPrice)
            users[msg.sender].balance -= ticketPrice;
        else {
            uint256 rest = ticketPrice - thisValue;
            thisValue = 0;
            users[msg.sender].balance -= rest;
        }
        users[msg.sender].balance += thisValue;
        allTickets[ticketCount] = LotteryTicket(templateId_,
                                                for_,
                                                uniqueMessage_,
                                                block.timestamp);
        ticketsToRound[ticketCount] = lotteryRounds.length - 1;
        lotteryRounds[lotteryRounds.length - 1].ticketCount++;
        ticketCount++;

    }

    /*
     * Get pot value for a round
     * -------------------------
     * Calculate the value of the pot for a round
     *
     * @param uint roundID_
     *        The identifier of the round to calculate for.
     *
     * @return uint256
     *         The value of the total available pot in the smallest unit (wei).
     */
    function _getPot(uint roundID_) internal view returns (uint256) {

        uint256 result;
        result = lotteryRounds[roundID_].ticketCount * ticketPrice;
        if (lotteryRounds[roundID_].ticketCount > 100)
            result = _percentageOf(90, result);
        else result = _percentageOf(10, result);
        return result;

    }

    /*
     * Generate pseudo-random number
     * -----------------------------
     * Perform construction of a pseudo radnom number if a given interval
     *
     * @param bytes32 seed_
     *        The seed for the pseudo-random process.
     * @aparm uint incl_min_
     *        The minimum (inclusive) number of the created value.
     * @param uint incl_max_
     *        The maximum (inclusive) number of the created value.
     *
     * @return uint
               The generated number.
     */
    function _getRandomInInterval(bytes32 seed_, uint incl_min_, uint incl_max_)
                                  internal view returns (uint) {

        uint range = incl_max_ - incl_min_ + 1;
        uint helper = uint(keccak256(abi.encodePacked(block.timestamp, seed_)))
                      % range;
        return incl_max_ - helper;

    }

    /*
     * Generate pseudo-random seed
     * ---------------------------
     * Perform construction of a pseudo radnom seed
     *
     * @return bytes32
               The generated seed value in form oy a bytes32 object.
     */
    function _getSeed() internal view returns (bytes32) {

        return blockhash(block.number);

    }

    /*
     * Collect tickets of a round
     * --------------------------
     * Collect all tickets that belong to a round
     *
     * @param uint roundID_
     *        The ID of the round to collect tickets for.
     *
     * @return LotteryTicket[] memory
     *         Array of tickets that belong to the given round.
     */
    function _getTicketsForRound(uint roundID_) internal view
                                 returns (LotteryTicket[] memory) {

        uint256 count = lotteryRounds[roundID_].ticketCount;
        LotteryTicket[] memory result = new LotteryTicket[](count);
        uint256 counter = 0;
        uint256 position = 0;
        while (counter < count && position < ticketCount) {
            if (ticketsToRound[position] == roundID_) {
                result[counter] = allTickets[position];
                counter++;
            }
            position++;
        }
        return result;

    }

    /*
     * Calculate percentage
     * --------------------
     * Perform percentage calculation with some safe math care
     *
     * @param uint256 percentage_
     *        Percentage to calculate.
     * @param uint256 value_
     *        Value to apply percentage on.
     */
    function _percentageOf(uint256 percentage_, uint256 value_)
                           internal pure returns (uint256) {

        uint256 result = (percentage_ * value_) / 100;
        return result;

    }

    /*
     * Transfer to user
     * ----------------
     * Perform an in-contract transform to the user's baalnce
     *
     * @param address user_
     *        The address of the user to transfer for.
     * @param uint256 amount_
     *        The amount to transfer for the user.
     */
    function _transferPrize(address user_, uint256 amount_)
                            onlyAvailableUser(user_)
                            internal {

        users[user_].balance += amount_;

    }


    // #############
    // # MODIFIERS #
    // #############

    /*
     * Authorize contract owner
     * ------------------------
     * Perform contrac owner authorization
     *
     * @param string calldata sentence_
     *        A sentence to ensure admin call.
     */
    modifier onlyAdmin(string calldata sentence_) {

        require(msg.sender == rootUser, 'Only root can perform this action.');
        require(keccak256(abi.encodePacked(sentence_)) == rootKey,
                'This action requires authorization.');
        _;

    }

    /*
     * Check user availability
     * -----------------------
     * Perform check whether the user is available or not
     *
     * @param address user_
     *        User to perform availability check for.
     */
    modifier onlyAvailableUser(address user_) {

        require(users[user_].state == USER_EXISTS_AND_AVAILABLE ||
                users[user_].state == USER_NOT_EXIST,
                'This action require an available user.');
        users[user_].state = USER_EXISTS_AND_LOCED;
        _;
        users[user_].state = USER_EXISTS_AND_AVAILABLE;

    }

    /*
     * Check round draw availability
     * -----------------------------
     * Perform check whether draw for the actual round is available or not
     */
    modifier onlyIfDrawAvailable() {

        require(lotteryRounds[lotteryRounds.length - 1].state == ROUND_OPEN ||
                lotteryRounds[lotteryRounds.length - 1].state
                == ROUND_NO_MORE_TICKETS,
                'Inappropriate rounb state.');
        require(lotteryRounds[lotteryRounds.length - 1].beginTime
                + lotteryRoundInterval < block.timestamp,
                'Cannot finish this round.');
        lotteryRounds[lotteryRounds.length - 1].state = ROUND_UNDER_DRAW;
        _;
        lotteryRounds[lotteryRounds.length - 1].state = ROUND_FINISHED;
        _createRound();

    }

    /*
     * Check round state
     * -----------------
     * Perform check whether the actual round is open or not
     */
    modifier onlyOpenRound() {

        require(lotteryRounds[lotteryRounds.length - 1].state == ROUND_OPEN,
                'Round must be open to perform this action.');
        if (lotteryRounds[lotteryRounds.length - 1].beginTime + ticketPeriod
            < block.timestamp) {
            lotteryRounds[lotteryRounds.length - 1].state =
                                                        ROUND_NO_MORE_TICKETS;
            revert('Round must be open for new tickets to perform this action.');
        }
        _;

    }

    // ###################
    // # ADMIN VARIABLES #
    // ###################

    bytes32 private rootKey;

    // ###########
    // # STRUCTS #
    // ###########

    struct JackpotRecord {
        uint roundID;
        address winner;
        uint256 amount;
    }

    struct LotteryRound {
        uint8 state;
        uint256 beginTime;
        uint256 drawTime;
        uint256 ticketCount;
        bytes32 openHash;
        bytes32 drawHash;
        uint8 winnersCount;
        uint8 jackpotState;
        address[] winners;
    }

    struct LotteryTicket {
        uint templateId;
        address owner;
        string uniqueMessage;
        uint256 boughtTime;
    }

    struct TicketInfo {
        uint roundID;
        uint ticketID;
        LotteryTicket ticket;
    }

    struct UserRecord {
        uint8 state;
        uint256 balance;
    }

    struct UIRecord {
        uint roundID;
        uint8 roundState;
        uint256 endTime;
        uint256 ticketsAvailable;
        uint256 prizePool;
        address[] winners;
        uint256 wonPrizePerWinner;
        uint256 jackpot;
        uint256 lastwonJackpotTime;
        uint256 lastwonJackpotAmount;
        address lastJackpotAddress;
    }

    // #############
    // # CONSTANTS #
    // #############

    uint8 constant ROUND_NOT_SET = 0;
    uint8 constant ROUND_OPEN = 1;
    uint8 constant ROUND_NO_MORE_TICKETS = 2;
    uint8 constant ROUND_UNDER_DRAW = 3;
    uint8 constant ROUND_FINISHED = 4;

    uint8 constant USER_NOT_EXIST = 0;
    uint8 constant USER_EXISTS_AND_AVAILABLE = 1;
    uint8 constant USER_EXISTS_AND_LOCED = 2;

    // ####################
    // # PUBLIC VARIABLES #
    // ####################

    JackpotRecord[] public jackpots;
    LotteryRound[] public lotteryRounds;
    bytes[] public lotteryTicketTemplates;

    address payable public rootUser;
    uint256 public lotteryRoundInterval;
    uint256 public ticketPeriod;
    uint256 public firstlotteryRoundTime;
    uint256 public ticketPrice;
    uint256 public jackpot;

    // #####################
    // # PRIVATE VARIABLES #
    // #####################

    mapping (address => UserRecord) private users;
    mapping (uint256 => LotteryTicket) private allTickets;
    mapping (uint256 => uint) private ticketsToRound;
    uint256 ticketCount;
    // mapping (address => address[]) private referrerChain;

}

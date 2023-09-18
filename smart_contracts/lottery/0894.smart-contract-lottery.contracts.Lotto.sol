// SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;
pragma solidity ^0.8.7;

import "./VRFv2SubscriptionManager.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "hardhat/console.sol";

/* Custom errors */
error Lotto__AllTicketsSold();
error Lotto__BetsCouldCauseOverflow();
error Lotto__EthTransferFailed();
error Lotto__HasNotEnded();
error Lotto__HasNotStarted();
error Lotto__HasStarted();
error Lotto__IndexOutOfBounds();
error Lotto__InvalidCaller();
error Lotto__MinBiggerThanMax();
error Lotto__NotContractOwner();
error Lotto__NotEnoughEth();
error Lotto__NotEnoughLinkToken();
error Lotto__NotOpenForCleaning();
error Lotto__NotTicketOwner();
error Lotto__NotUpkeepRegistry();
error Lotto__StillOpen();
error Lotto__TicketChecked();
error Lotto__TicketClaimed();
error Lotto__TicketNotChecked();
error Lotto__TicketNotWinner();
error Lotto__TicketSellClosed();
error Lotto__TooMuchEth();
error Lotto__TotalTicketsCanNotBeZero();
error Lotto__WinnersBeingSorted();
error Lotto__WinnersSorted();

/**
 * @title Automated truly random lotto where the players can place a bet
 * and when they win they receive the payout of the size of their initial
 * bet plus a share from the losers bets. Proportionate to all the winners
 * bets total. One of every four sequential tickets bought will win.
 * @author Jaak Kivinukk
 */
contract Lotto is AutomationCompatibleInterface {
    /* State variables */
    VRFv2SubscriptionManager private immutable i_VRFv2SubscriptionManager;
    LinkTokenInterface private immutable i_LinkToken;
    mapping(uint256 => Ticket) private s_tickets;
    mapping(address => uint256[]) private s_ownedTicketNumbers;
    address private immutable i_owner;
    address private immutable i_registry;
    uint256[] private s_betStacks = new uint256[](256);
    uint256 private s_balance;
    uint256 private s_soldTickets;
    uint256 private s_winnersBets;
    uint256 private s_losersBets;
    uint256 private s_ownersFee;
    uint256 private s_startTime;
    uint256 private s_winnersSortedTime;
    uint256 private immutable i_totalTickets;
    uint256 private immutable i_minBet;
    uint256 private immutable i_maxBet;
    uint256 private immutable i_duration;
    uint256 private immutable i_blockNumber;
    uint256 private s_winningNumber;
    uint256 private constant SECONDS_IN_THIRTY_DAYS = 2_592_000;
    uint32 private s_vrfv2CallbackGasLimit = 500_000;
    bool private s_hasLotteryStarted;
    bool private s_hasLotteryEnded;
    bool private s_isWaitingWinningNumber;
    bool private s_isWinningNumberRecived;
    bool private s_isFindingWinners;

    /* Structs */
    struct Ticket {
        address owner;
        uint256 bet;
        bool isChecked;
        bool isWinner;
        bool isClaimed;
    }

    /* Events */
    event LotteryStart(
        address indexed lottery,
        uint256 indexed startTime,
        uint256 totalTickets,
        uint256 minBet,
        uint256 maxBet,
        uint256 duration
    );
    event TicketBuy(
        uint256 indexed ticketNumber,
        address indexed owner,
        uint256 indexed time,
        uint256 bet
    );
    event TicketCheck(
        address indexed owner,
        uint256 indexed ticketNumber,
        uint256 time,
        bool indexed isWinner
    );
    event TicketClaim(
        address indexed owner,
        uint256 indexed ticketNumber,
        uint256 time,
        uint256 winningSum
    );
    event Clean(address indexed lottery, uint256 indexed remainingBalance);
    event WinningNumberRequest(address indexed lottery, uint256 time);
    event WinningNumberReceived(
        address indexed lottery,
        uint256 winningNumber,
        uint256 time
    );
    event LotteryEnd(
        address indexed lottery,
        uint256 indexed endTime,
        uint256 soldTickets,
        uint256 winnersBets,
        uint256 losersBets,
        uint256 duration
    );

    constructor(
        address linkToken,
        address vrfCoordinator,
        address registry,
        bytes32 keyHash,
        uint256 totalTickets,
        uint256 minBet,
        uint256 maxBet,
        uint256 duration
    ) {
        if (minBet > maxBet) revert Lotto__MinBiggerThanMax();
        if (totalTickets == 0) revert Lotto__TotalTicketsCanNotBeZero();
        unchecked {
            uint256 maxBalance = totalTickets * maxBet;
            if (maxBalance / totalTickets != maxBet)
                revert Lotto__BetsCouldCauseOverflow();
        }
        i_VRFv2SubscriptionManager = new VRFv2SubscriptionManager(
            address(this),
            linkToken,
            vrfCoordinator,
            keyHash
        );
        i_LinkToken = LinkTokenInterface(linkToken);
        i_registry = registry;
        i_owner = msg.sender;
        i_totalTickets = totalTickets;
        i_minBet = minBet;
        i_maxBet = maxBet;
        i_duration = duration;
        i_blockNumber = block.number;
    }

    /* Automation compatible lifecycle methods */

    /**
     * @dev When the time of the lottery has ended then the first the upkeep is triggered
     * to obtain the random number through the Chainlink VRF oracle. When that has been
     * received then again upkeep is triggered but at the same time the winners are being
     * sorted regards to that random number. The logic is setup in a way that every bought
     * ticket will go into 256 sequential stacks. When the last 256 stack is reached it
     * starts from the start again. As the uint256 has 256 bits then the bits of the
     * random number are being used to decide which stack from every four stacks is a winner
     * using the first two high order bits from every sequential four bits.
     * Better explained visually:
     *
     * 00 00 \
     * 00 01  \ Stack 1 wins from the current 4.
     * 00 10  / ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
     * 00 11 /
     * 01 00 \
     * 01 01  \ Stack 2 wins from the current 4.
     * 01 10  / ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
     * 01 11 /
     * 10 00 \
     * 10 01  \ Stack 3 wins from the current 4.
     * 10 10  / ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
     * 10 11 /
     * 11 00 \
     * 11 01  \ Stack 4 wins from the current 4.
     * 11 10  / ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
     * 11 11 /
     *
     * In order to retrieve the bits from the random number I am using a mask
     * to check if the needed bit is on or off with the bitwise operation AND.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        onlyRegistry
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (
            !s_hasLotteryEnded &&
            s_hasLotteryStarted &&
            block.timestamp - s_startTime >= i_duration
        ) {
            if (!s_isWaitingWinningNumber) {
                upkeepNeeded = true;
            } else if (s_isWinningNumberRecived && !s_isFindingWinners) {
                upkeepNeeded = true;

                uint256[] memory betStacks = s_betStacks;
                uint256 arraySize = s_soldTickets > 256 ? 256 : s_soldTickets;
                uint256 loopIndexMax = arraySize - 4;
                uint256 mask = 1;
                uint256 winnersBets;
                uint256 winningNumber = s_winningNumber;
                bool ticketOneScore;
                bool ticketTwoScore;

                for (uint256 index = 0; index < loopIndexMax; ) {
                    ticketOneScore = (winningNumber & mask) > 0;
                    ticketTwoScore = (winningNumber & (mask * 2)) > 0;

                    if (!ticketOneScore && !ticketTwoScore) {
                        winnersBets += betStacks[index];
                        betStacks[index + 1] = 0;
                        betStacks[index + 2] = 0;
                        betStacks[index + 3] = 0;
                    } else if (!ticketOneScore && ticketTwoScore) {
                        winnersBets += betStacks[index + 1];
                        betStacks[index] = 0;
                        betStacks[index + 2] = 0;
                        betStacks[index + 3] = 0;
                    } else if (ticketOneScore && !ticketTwoScore) {
                        winnersBets += betStacks[index + 2];
                        betStacks[index] = 0;
                        betStacks[index + 1] = 0;
                        betStacks[index + 3] = 0;
                    } else {
                        winnersBets += betStacks[index + 3];
                        betStacks[index] = 0;
                        betStacks[index + 1] = 0;
                        betStacks[index + 2] = 0;
                    }

                    unchecked {
                        mask *= 16;
                        index += 4;
                    }
                }

                ticketOneScore = (winningNumber & mask) > 0;
                ticketTwoScore = (winningNumber & (mask * 2)) > 0;

                if (!ticketOneScore && !ticketTwoScore) {
                    winnersBets += betStacks[loopIndexMax];
                    betStacks[arraySize - 3] = 0;
                    betStacks[arraySize - 2] = 0;
                    betStacks[arraySize - 1] = 0;
                } else if (!ticketOneScore && ticketTwoScore) {
                    winnersBets += betStacks[arraySize - 3];
                    betStacks[loopIndexMax] = 0;
                    betStacks[arraySize - 2] = 0;
                    betStacks[arraySize - 1] = 0;
                } else if (ticketOneScore && !ticketTwoScore) {
                    winnersBets += betStacks[arraySize - 2];
                    betStacks[loopIndexMax] = 0;
                    betStacks[arraySize - 3] = 0;
                    betStacks[arraySize - 1] = 0;
                } else {
                    winnersBets += betStacks[arraySize - 1];
                    betStacks[loopIndexMax] = 0;
                    betStacks[arraySize - 3] = 0;
                    betStacks[arraySize - 2] = 0;
                }

                performData = abi.encode(winnersBets, betStacks);
            }
        }
    }

    /**
     * @dev First time when launched it requests the random number from the
     * Chainlink VRF. Second time calls the internal method _findWinners()
     * passing on the winners data calculated in the checkUpkeep() method.
     */
    function performUpkeep(bytes calldata performData)
        external
        override
        onlyRegistry
    {
        if (
            !s_hasLotteryEnded &&
            s_hasLotteryStarted &&
            block.timestamp - s_startTime >= i_duration
        ) {
            if (!s_isWaitingWinningNumber) {
                _requestWinningNumber();
            } else if (s_isWinningNumberRecived && !s_isFindingWinners) {
                _findWinnners(performData);
            }
        }
    }

    /* Interaction methods */

    /**
     * @dev Method for the owner that starts the lottery if
     * the VRF subscription manager has enough LINK Token and
     * when it has not been called already.
     *
     * Emits a {StartLottery} event.
     */
    function startLottery() public onlyOwner {
        if (s_hasLotteryStarted) revert Lotto__HasStarted();
        if (
            i_LinkToken.balanceOf(address(i_VRFv2SubscriptionManager)) !=
            5_000_000_000_000_000_000
        ) revert Lotto__NotEnoughLinkToken();
        s_hasLotteryStarted = true;
        s_startTime = block.timestamp;
        i_VRFv2SubscriptionManager.createNewSubscription();
        emit LotteryStart(
            address(this),
            s_startTime,
            i_totalTickets,
            i_minBet,
            i_maxBet,
            i_duration
        );
    }

    /**
     * @dev Method for the players to buy tickets. It has a check
     * if the ticket sell is still open and if the bet stays in the
     * allowed range. Then adds the ticket in the current active
     * bet stack.
     *
     * Emits a {TicketBuy} event.
     */
    function buyTicket()
        public
        payable
        onlyStarted
        returns (uint256 soldTickets)
    {
        if (block.timestamp - s_startTime >= i_duration)
            revert Lotto__TicketSellClosed();
        soldTickets = s_soldTickets;

        if (soldTickets >= i_totalTickets) revert Lotto__AllTicketsSold();
        if (msg.value < i_minBet) revert Lotto__NotEnoughEth();
        if (msg.value > i_maxBet) revert Lotto__TooMuchEth();

        s_tickets[soldTickets] = Ticket(
            msg.sender,
            msg.value,
            false,
            false,
            false
        );
        s_ownedTicketNumbers[msg.sender].push(soldTickets);
        s_betStacks[soldTickets % 256] += msg.value;
        s_balance += msg.value;
        emit TicketBuy(soldTickets, msg.sender, block.timestamp, msg.value);
        s_soldTickets = ++soldTickets;
    }

    /**
     * @dev Method for the players to check their tickets after the lottery
     * has ended in order did they win or not. All the losing bet stacks
     * are set to zero.
     *
     * Emits a {TicketCheck} event.
     */
    function checkTicket(uint256 ticketIndex)
        public
        onlyTicketOwner(ticketIndex)
        onlyEnded
        returns (bool isWinner)
    {
        if (s_tickets[ticketIndex].isChecked) revert Lotto__TicketChecked();

        s_tickets[ticketIndex].isChecked = true;
        isWinner = s_betStacks[ticketIndex % 256] > 0;
        s_tickets[ticketIndex].isWinner = isWinner;
        emit TicketCheck(msg.sender, ticketIndex, block.timestamp, isWinner);
    }

    /**
     * @dev Methods for the players to claim their ticket after they have
     * checked the ticket.
     *
     * Emits a {TicketClaim} event.
     */
    function claimTicket(uint256 ticketIndex)
        public
        onlyTicketOwner(ticketIndex)
    {
        Ticket memory ticket = s_tickets[ticketIndex];

        if (!ticket.isChecked) revert Lotto__TicketNotChecked();
        if (ticket.isClaimed) revert Lotto__TicketClaimed();

        s_tickets[ticketIndex].isClaimed = true;

        if (!ticket.isWinner) revert Lotto__TicketNotWinner();

        uint256 ticketValue = ticket.bet;
        ticketValue -= (ticketValue * 3) / 100;

        uint256 winningSum = ticketValue +
            ((ticketValue * s_losersBets) / s_winnersBets);

        (bool success, ) = payable(ticket.owner).call{value: winningSum}("");

        if (!success) revert Lotto__EthTransferFailed();
        emit TicketClaim(msg.sender, ticketIndex, block.timestamp, winningSum);
    }

    /**
     * @dev Method for the owner to clean the contract from any remaining funds.
     * Which minimally is the owners fee but could be some extra if the players
     * have not claimed their ticket after 30 days after the end of the lottery.
     *
     * Emits a {Clean} event.
     */
    function clean() public onlyOwner onlyEnded {
        if (block.timestamp - s_winnersSortedTime < SECONDS_IN_THIRTY_DAYS)
            revert Lotto__NotOpenForCleaning();
        uint256 remainingBalance = address(this).balance;
        (bool success, ) = payable(i_owner).call{value: remainingBalance}("");

        if (!success) revert Lotto__EthTransferFailed();
        emit Clean(address(this), remainingBalance);
    }

    /* Internal methods */

    /**
     * @dev Method for requesting the random number from the Chainlink VRF.
     *
     * Emits a {WinningNumberRequest} event.
     */
    function _requestWinningNumber() internal onlyStarted {
        if (block.timestamp - s_startTime < i_duration)
            revert Lotto__StillOpen();
        if (s_isWaitingWinningNumber) revert Lotto__WinnersBeingSorted();
        s_isWaitingWinningNumber = true;
        i_VRFv2SubscriptionManager.requestRandomWords(s_vrfv2CallbackGasLimit);
        emit WinningNumberRequest(address(this), block.timestamp);
    }

    /**
     * @dev Method for finding the winners. Most of it logic was
     * moved to the checkUpkeep() method to save gas and here only
     * the storage variables are overwritten accordingly.
     * @param performData Winners data from the checkUpkeep() method.
     *
     * Emits a {LotteryEnd} event.
     */
    function _findWinnners(bytes calldata performData) internal {
        s_isFindingWinners = true;

        (uint256 winnersBets, uint256[] memory betStacks) = abi.decode(
            performData,
            (uint256, uint256[])
        );

        uint256 balance = s_balance;

        s_winnersBets = (winnersBets * 97) / 100;
        s_losersBets = ((balance - winnersBets) * 97) / 100;
        s_ownersFee = (balance * 3) / 100;
        s_betStacks = betStacks;
        s_winnersSortedTime = block.timestamp;
        s_hasLotteryEnded = true;
        emit LotteryEnd(
            address(this),
            s_winnersSortedTime,
            s_soldTickets,
            winnersBets,
            s_losersBets,
            i_duration
        );
    }

    /* External methods */

    /**
     * @dev Method for the VRF subscription manager.
     * @param winningNumber The Chainlink VRF generated random number.
     *
     * Emits a {WinningNumberReceived} event.
     */
    function _receiveWinningNumber(uint256 winningNumber) external {
        if (msg.sender != address(i_VRFv2SubscriptionManager))
            revert Lotto__InvalidCaller();
        s_winningNumber = winningNumber;
        s_isWinningNumberRecived = true;
        emit WinningNumberReceived(
            address(this),
            winningNumber,
            block.timestamp
        );
    }

    /* Getters & setters */

    /**
     * @dev Method for the players to view their tickets.
     * @param ticketIndex Index of the their bought ticket other words ticket ID.
     */
    function getTicket(uint256 ticketIndex)
        public
        view
        onlyTicketOwner(ticketIndex)
        returns (Ticket memory ticket)
    {
        ticket = s_tickets[ticketIndex];
    }

    /**
     * @dev Method for the players to get all their bought tickets indexes.
     * @return ownedTicketNumbers Indexes of the sender bought tickets.
     */
    function getOwnedTicketNumbers()
        public
        view
        returns (uint256[] memory ownedTicketNumbers)
    {
        ownedTicketNumbers = s_ownedTicketNumbers[msg.sender];
    }

    /**
     * @dev Method for checking how much time is left till the end of the lottery.
     * @return timeLeft Time left till the end of the lottery.
     */
    function getTimeLeft() public view onlyStarted returns (uint256 timeLeft) {
        if (block.timestamp - s_startTime >= i_duration) {
            timeLeft = 0;
        } else {
            timeLeft = i_duration - (block.timestamp - s_startTime);
        }
    }

    /**
     * @dev Method for checking how much has been staked in a specific stack.
     * @return betStack Betstack at the requested index.
     */
    function getBetStack(uint256 betStackIndex)
        public
        view
        onlyOwner
        returns (uint256 betStack)
    {
        if (betStackIndex >= s_betStacks.length)
            revert Lotto__IndexOutOfBounds();
        betStack = s_betStacks[betStackIndex];
    }

    function getVRFv2SubscriptionManager()
        public
        view
        returns (VRFv2SubscriptionManager vrfv2SubscriptionManager)
    {
        vrfv2SubscriptionManager = i_VRFv2SubscriptionManager;
    }

    function getHasLotteryStarted() public view returns (bool isStarted) {
        isStarted = s_hasLotteryStarted;
    }

    function getHasLotteryEnded() public view returns (bool isEnded) {
        isEnded = s_hasLotteryEnded;
    }

    function getSoldTickets() public view returns (uint256 soldTickets) {
        soldTickets = s_soldTickets;
    }

    function getWinningNumber() public view returns (uint256 winningNumber) {
        winningNumber = s_winningNumber;
    }

    function getWinnersBets() public view returns (uint256 winnersBets) {
        winnersBets = s_winnersBets;
    }

    function getLosersBets() public view returns (uint256 losersBets) {
        losersBets = s_losersBets;
    }

    function getOwnersFee() public view returns (uint256 ownersFee) {
        ownersFee = s_ownersFee;
    }

    function getTotalTickets() public view returns (uint256 totalTickets) {
        totalTickets = i_totalTickets;
    }

    function getMinBet() public view returns (uint256 minBet) {
        minBet = i_minBet;
    }

    function getMaxBet() public view returns (uint256 maxBet) {
        maxBet = i_maxBet;
    }

    function getStartTime() public view returns (uint256 startTime) {
        startTime = s_startTime;
    }

    function getDuration() public view returns (uint256 duration) {
        duration = i_duration;
    }

    function setVrfV2CallbackGasLimit(uint32 callbackGasLimit)
        public
        onlyOwner
    {
        s_vrfv2CallbackGasLimit = callbackGasLimit;
    }

    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = i_blockNumber;
    }

    /* Modifiers */
    modifier onlyTicketOwner(uint256 ticketIndex) {
        if (s_tickets[ticketIndex].owner != msg.sender)
            revert Lotto__NotTicketOwner();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Lotto__NotContractOwner();
        _;
    }

    modifier onlyEnded() {
        if (!s_hasLotteryEnded) revert Lotto__HasNotEnded();
        _;
    }

    modifier onlyStarted() {
        if (!s_hasLotteryStarted) revert Lotto__HasNotStarted();
        _;
    }

    modifier onlyRegistry() {
        if (msg.sender != i_registry) revert Lotto__NotUpkeepRegistry();
        _;
    }
}

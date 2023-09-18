// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error SmartLotteryV2__PrizeDistributionNotOneHundredPercent();
error SmartLotteryV2__LotteryNotOpen();
error SmartLotteryV2__TooManyTickets();
error SmartLotteryV2__NotEnoughFunds();
error SmartLotteryV2__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 lotteryState
);
error SmartLotteryV2__NonExistingLottery();
error SmartLotteryV2__TicketsAlreadyRevealed();
error SmartLotteryV2__ExternalCallFailed();
error SmartLotteryV2__NoPendingRewards();

/**
 * @title SmartLotteryV2
 * @author jrmunchkin
 * @notice This contract creates a ticket lottery which will picked a random winning ticket once the lottery end.
 * The player must buy tickets to play the lottery, he also must pay fee everytime buying a ticket.
 * The lottery works like so :
 * - The pot is divided into 4 pots. The size of each pot is based on a percentage set in the constructor.
 * - Everytime the user buy a ticket he get 4 random numbers. Maximum buying ticket : 10 per user per lottery.
 * - If the user has a ticket with the first number matching the winning ticket he win the smallest pot.
 * - If the user has a ticket with the two first number matching the winning ticket he win the second pot.
 * - If the user has a ticket with the third first number matching the winning ticket he win the third pot.
 * - If the user has a ticket with the fourth number matching the winning ticket he win the biggest pot.
 * - Each pot is also divided by the number of user who win it.
 * @dev The constructor takes an interval (time of duration of the lottery), an usd entrance fee (entrance fee in dollars)
 * and a prize distribution corresponding on the percentage of each pots.
 * This contract implements Chainlink Keeper to trigger when the lottery must end.
 * This contract implements Chainlink VRF to pick a random winning ticket when the lottery ends.
 * This contract also implements the Chainlink price feed to know the ticket fee value in ETH.
 */
contract SmartLotteryV2 is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum LotteryState {
        OPEN,
        DRAW_WINNING_TICKET
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_usdTicketFee;
    uint256 private immutable i_interval;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 4;
    uint256 private constant MAX_BUYING_TICKET = 10;
    LotteryState private s_lotteryState;
    uint256 private s_lotteryNumber;
    uint256 private s_randNonce;
    address[] private s_players;
    uint256 private s_startTimestamp;
    uint256[NUM_WORDS] private s_prizeDistribution;

    mapping(uint256 => uint256) private s_lotteryBalance;
    mapping(address => uint256) private s_rewardsBalance;
    mapping(uint256 => mapping(string => uint256))
        private s_numberOfCombination;
    mapping(uint256 => mapping(address => uint256[NUM_WORDS][]))
        private s_playerTickets;
    mapping(uint256 => mapping(address => bool))
        private s_playerTicketsRevealed;
    mapping(uint256 => uint256[NUM_WORDS]) private s_winningTicket;

    event StartLottery(uint256 indexed lotteryNumber, uint256 startTime);
    event EnterLottery(uint256 indexed lotteryNumber, address indexed player);
    event EmitTicket(
        uint256 indexed lotteryNumber,
        address indexed player,
        uint256[NUM_WORDS] ticket
    );
    event RequestLotteryWinningTicket(
        uint256 indexed lotteryNumber,
        uint256 indexed requestId
    );
    event WinningTicketLotteryPicked(
        uint256 indexed lotteryNumber,
        uint256[NUM_WORDS] ticket
    );
    event RevealTicket(
        uint256 indexed lotteryNumber,
        address indexed player,
        uint256[NUM_WORDS] ticket,
        uint256 nbMatching
    );
    event ClaimLotteryRewards(address indexed winner, uint256 amount);

    /**
     * @notice contructor
     * @param _vrfCoordinatorV2 VRF Coordinator contract address
     * @param _subscriptionId Subscription Id of Chainlink VRF
     * @param _gasLane Gas lane of Chainlink VRF
     * @param _callbackGasLimit Callback gas limit of Chainlink VRF
     * @param _ethUsdPriceFeed Price feed address ETH to USD
     * @param _usdTicketFee Ticket fee value in dollars
     * @param _interval Duration of the lottery
     * @param _prizeDistribution Array of prize distribution of each pot (the smallest first, total must be 100%)
     */
    constructor(
        address _vrfCoordinatorV2,
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        address _ethUsdPriceFeed,
        uint256 _usdTicketFee,
        uint256 _interval,
        uint256[NUM_WORDS] memory _prizeDistribution
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        uint256 prizeDistributionTotal = 0;
        for (
            uint256 prizeDistributionIndex = 0;
            prizeDistributionIndex < _prizeDistribution.length;
            prizeDistributionIndex++
        ) {
            prizeDistributionTotal =
                prizeDistributionTotal +
                uint256(_prizeDistribution[prizeDistributionIndex]);
        }
        if (prizeDistributionTotal != 100)
            revert SmartLotteryV2__PrizeDistributionNotOneHundredPercent();
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        i_usdTicketFee = _usdTicketFee * (10 ** 18);
        i_interval = _interval;
        s_randNonce = 0;
        s_lotteryNumber = 1;
        s_prizeDistribution = _prizeDistribution;
        s_lotteryState = LotteryState.OPEN;
    }

    /**
     * @notice Allow user to buy tickets to enter the lottery by paying ticket fee
     * @param _numberOfTickets The number of ticket the user want to buy
     * @dev When the first player enter the lottery the duration start
     * emit an event EnterLottery when player enter the lottery
     * emit an event EmitTicket for each ticket the player buys
     * emit an event StartLottery the lottery duration start
     */
    function buyTickets(uint256 _numberOfTickets) external payable {
        if (s_lotteryState != LotteryState.OPEN)
            revert SmartLotteryV2__LotteryNotOpen();
        if (
            s_playerTickets[s_lotteryNumber][msg.sender].length +
                _numberOfTickets >
            MAX_BUYING_TICKET
        ) revert SmartLotteryV2__TooManyTickets();
        if (msg.value < getTicketFee() * _numberOfTickets)
            revert SmartLotteryV2__NotEnoughFunds();
        if (!isPlayerAlreadyInLottery(msg.sender)) {
            s_players.push(msg.sender);
            emit EnterLottery(s_lotteryNumber, msg.sender);
            if (s_players.length == 1) {
                s_startTimestamp = block.timestamp;
                emit StartLottery(s_lotteryNumber, s_startTimestamp);
            }
        }
        for (
            uint256 ticketIndex = 0;
            ticketIndex < _numberOfTickets;
            ticketIndex++
        ) {
            uint256[NUM_WORDS] memory ticket = [
                getRandomNumber(),
                getRandomNumber(),
                getRandomNumber(),
                getRandomNumber()
            ];
            s_playerTickets[s_lotteryNumber][msg.sender].push(ticket);
            setNumberOfCombinations(s_lotteryNumber, ticket);
            emit EmitTicket(s_lotteryNumber, msg.sender, ticket);
        }
        s_lotteryBalance[s_lotteryNumber] += msg.value;
    }

    /**
     * @notice Chainlink checkUpkeep which will check if lottery must end
     * @return upkeepNeeded boolean to know if Chainlink must perform upkeep
     * @dev Lottery end when all this assertions are true :
     * The lottery is open
     * The lottery have at least one player
     * The lottery have some balance
     * The lottery duration is over
     */
    function checkUpkeep(
        bytes memory /* _checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = s_lotteryState == LotteryState.OPEN;
        bool timePassed = ((block.timestamp - s_startTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = s_lotteryBalance[s_lotteryNumber] > 0;
        upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Chainlink performUpkeep which will end the lottery
     * @dev This function is call if upkeepNeeded of checkUpkeep is true
     * Call Chainlink VRF to request a random winning ticket
     * emit an event RequestLotteryWinningTicket when request winning ticket is called
     */
    function performUpkeep(
        bytes calldata /* _performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert SmartLotteryV2__UpkeepNotNeeded(
                s_lotteryBalance[s_lotteryNumber],
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.DRAW_WINNING_TICKET;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestLotteryWinningTicket(s_lotteryNumber, requestId);
    }

    /**
     * @notice Picked a random winning ticket and restart lottery
     * @dev Call by the Chainlink VRF after requesting a random winning ticket
     * emit an event WinningTicketLotteryPicked when random winning ticket has been picked
     */
    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        uint256[NUM_WORDS] memory winningTicket = [
            _randomWords[0] % 10,
            _randomWords[1] % 10,
            _randomWords[2] % 10,
            _randomWords[3] % 10
        ];
        s_winningTicket[s_lotteryNumber] = winningTicket;
        postponeLotteryBalance();
        s_players = new address[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lotteryNumber++;
        emit WinningTicketLotteryPicked(s_lotteryNumber - 1, winningTicket);
    }

    /**
     * @notice Allow user to reveal if his tickets are winning tickets for a specific lottery
     * @param _lotteryNumber The number of the lottery
     * emit an event RevealTicket for each ticket revealed
     */
    function revealWinningTickets(uint256 _lotteryNumber) external {
        if (_lotteryNumber < 1 || _lotteryNumber >= s_lotteryNumber)
            revert SmartLotteryV2__NonExistingLottery();
        if (isPlayerTicketAlreadyRevealed(msg.sender, _lotteryNumber))
            revert SmartLotteryV2__TicketsAlreadyRevealed();
        uint256 totalRewards = 0;

        uint256[NUM_WORDS] memory winningTicket = s_winningTicket[
            _lotteryNumber
        ];
        for (
            uint256 ticketIndex = 0;
            ticketIndex < s_playerTickets[_lotteryNumber][msg.sender].length;
            ticketIndex++
        ) {
            uint256[NUM_WORDS] memory ticket = s_playerTickets[_lotteryNumber][
                msg.sender
            ][ticketIndex];
            uint256 nbMatching = getNumberOfMatching(ticket, winningTicket);
            uint256 nbCombination = getNumberOfCombinations(
                _lotteryNumber,
                nbMatching,
                ticket
            );
            totalRewards =
                totalRewards +
                getPrizeForMatching(_lotteryNumber, nbMatching, nbCombination);
            emit RevealTicket(_lotteryNumber, msg.sender, ticket, nbMatching);
        }
        s_rewardsBalance[msg.sender] =
            s_rewardsBalance[msg.sender] +
            totalRewards;
        s_playerTicketsRevealed[_lotteryNumber][msg.sender] = true;
    }

    /**
     * @notice Allow user to claim his lottery rewards
     * emit an event ClaimLotteryRewards when user claimed his rewards
     */
    function claimRewards() external {
        if (s_rewardsBalance[msg.sender] <= 0)
            revert SmartLotteryV2__NoPendingRewards();
        uint256 toTransfer = s_rewardsBalance[msg.sender];
        s_rewardsBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: toTransfer}("");
        if (!success) revert SmartLotteryV2__ExternalCallFailed();
        emit ClaimLotteryRewards(msg.sender, toTransfer);
    }

    /**
     * @notice Set the combinations for a specific ticket
     * @param _lotteryNumber The lottery number
     * @param _ticket The ticket
     * @dev This function aim to set how many times a combination appear on the same lottery
     * The purpose is to calulate at the end between how many user the pot need to be shared
     */
    function setNumberOfCombinations(
        uint256 _lotteryNumber,
        uint256[NUM_WORDS] memory _ticket
    ) internal {
        string memory combination = "";
        for (
            uint256 numberIndex = 0;
            numberIndex < _ticket.length;
            numberIndex++
        ) {
            combination = string(
                abi.encodePacked(
                    combination,
                    Strings.toString(uint256(_ticket[numberIndex]))
                )
            );
            s_numberOfCombination[_lotteryNumber][combination]++;
        }
    }

    /**
     * @notice Return a random number between 0 and 9
     * @return randomNumber Random number
     * @dev It's not a secure method to pick random number but as it's just to assign a ticket we can tolerate it
     */
    function getRandomNumber() internal returns (uint256) {
        s_randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, s_randNonce)
                )
            ) % 10;
    }

    /**
     * @notice Postpone the lottery pots which don't have any winners to the next lottery
     */
    function postponeLotteryBalance() internal {
        for (uint256 numberIndex = 1; numberIndex <= NUM_WORDS; numberIndex++) {
            uint256 numberOfCombination = getNumberOfCombinations(
                s_lotteryNumber,
                numberIndex,
                s_winningTicket[s_lotteryNumber]
            );
            if (numberOfCombination == 0) {
                uint256 poolDistribution = s_prizeDistribution[numberIndex - 1];
                uint256 prize = (s_lotteryBalance[s_lotteryNumber] *
                    poolDistribution) / 100;
                s_lotteryBalance[s_lotteryNumber + 1] =
                    s_lotteryBalance[s_lotteryNumber + 1] +
                    prize;
            }
        }
    }

    /**
     * @notice Return the number of matching number between a ticket and a winning ticket
     * @param _ticket The ticket to compare
     * @param _winningTicket The winning ticket
     * @return nbMatching The number of matching numbers
     */
    function getNumberOfMatching(
        uint256[NUM_WORDS] memory _ticket,
        uint256[NUM_WORDS] memory _winningTicket
    ) internal pure returns (uint256) {
        uint256 nbMatching = 0;
        for (
            uint256 numberIndex = 0;
            numberIndex < _ticket.length;
            numberIndex++
        ) {
            if (_ticket[numberIndex] != _winningTicket[numberIndex]) break;
            nbMatching++;
        }
        return nbMatching;
    }

    /**
     * @notice Get the number of combinations for a specific ticket and its number of matching numbers
     * @param _lotteryNumber The lottery number
     * @param _nbMatching The number of matching numbers
     * @param _ticket The ticket
     * @return numberOfCombination The number of combination
     */
    function getNumberOfCombinations(
        uint256 _lotteryNumber,
        uint256 _nbMatching,
        uint256[NUM_WORDS] memory _ticket
    ) internal view returns (uint256) {
        string memory combination = "";
        for (
            uint256 numberIndex = 0;
            numberIndex < _nbMatching;
            numberIndex++
        ) {
            combination = string(
                abi.encodePacked(
                    combination,
                    Strings.toString(uint256(_ticket[numberIndex]))
                )
            );
        }
        return s_numberOfCombination[_lotteryNumber][combination];
    }

    /**
     * @notice Return the amount a user will get from the number of matching numbers and the number of combinations
     * @param _lotteryNumber The lottery number
     * @param _nbMatching The number of matching numbers
     * @param _nbCombination The number of combination
     * @return prize The prize the user will get
     */
    function getPrizeForMatching(
        uint256 _lotteryNumber,
        uint256 _nbMatching,
        uint256 _nbCombination
    ) internal view returns (uint256) {
        uint256 prize = 0;
        if (_nbMatching == 0) return 0;
        uint256 poolDistribution = s_prizeDistribution[_nbMatching - 1];
        prize = (s_lotteryBalance[_lotteryNumber] * poolDistribution) / 100;
        return prize / _nbCombination;
    }

    /**
     * @notice Check if the user already play the lottery
     * @param _user address of the user
     * @return isPlaying true if already play, false ether
     */
    function isPlayerAlreadyInLottery(
        address _user
    ) internal view returns (bool) {
        for (
            uint256 playersIndex = 0;
            playersIndex < s_players.length;
            playersIndex++
        ) {
            if (s_players[playersIndex] == _user) return true;
        }
        return false;
    }

    /**
     * @notice Check if the user already revealed his tickets for the given lottery
     * @param _user address of the user
     * @param _lotteryNumber The number of the lottery
     * @return isAlreadyRevealed true if already revealed, false ether
     */
    function isPlayerTicketAlreadyRevealed(
        address _user,
        uint256 _lotteryNumber
    ) public view returns (bool) {
        return s_playerTicketsRevealed[_lotteryNumber][_user];
    }

    /**
     * @notice Get ticket fee to buy a ticket for the lottery
     * @return ticketFee Ticket fee in ETH
     * @dev Implements Chainlink price feed
     */
    function getTicketFee() public view returns (uint256) {
        (, int256 price, , , ) = i_ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        return (i_usdTicketFee * 10 ** 18) / adjustedPrice;
    }

    /**
     * @notice Get ticket fee in dollars to participate to the lottery
     * @return usdTicketFee Ticket fee in dollars
     */
    function getUsdTicketFee() external view returns (uint256) {
        return i_usdTicketFee;
    }

    /**
     * @notice Get duration of the lottery
     * @return interval Duration of the lottery
     */
    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    /**
     * @notice Get the prize distribution of the lottery
     * @return prizeDistribution Prize distribution of the lottery
     */
    function getPrizeDistribution()
        external
        view
        returns (uint256[NUM_WORDS] memory)
    {
        return s_prizeDistribution;
    }

    /**
     * @notice Get actual lottery number
     * @return lotteryNumber Actual lottery number
     */
    function getActualLotteryNumber() external view returns (uint256) {
        return s_lotteryNumber;
    }

    /**
     * @notice Get the state of the lottery
     * @return lotteryState Lottery state
     */
    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    /**
     * @notice Get player address with index
     * @param _index Index of player
     * @return player Player address
     */
    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    /**
     * @notice Get the number of players of the lottery
     * @return numPlayers Number of players
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    /**
     * @notice Get a specific ticket for the player on the lottery
     * @param _user user address
     * @param _index Index of ticket
     * @return ticket The player ticket
     */
    function getPlayerTicket(
        address _user,
        uint256 _index
    ) external view returns (uint256[NUM_WORDS] memory) {
        return s_playerTickets[s_lotteryNumber][_user][_index];
    }

    /**
     * @notice Get the number of ticket a player own in the lottery
     * @return numTicketPlayer Number of tickets for the player
     */
    function getNumberOfTicketsByPlayer(
        address _user
    ) external view returns (uint256) {
        return s_playerTickets[s_lotteryNumber][_user].length;
    }

    /**
     * @notice Get the number of time a combination appear
     * @return numCombination Number of combination
     */
    function getNumberOfCombination(
        string memory _combination
    ) external view returns (uint256) {
        return s_numberOfCombination[s_lotteryNumber][_combination];
    }

    /**
     * @notice Get the timestamp when the lottery start
     * @return startTimestamp Start timestamp
     */
    function getStartTimestamp() external view returns (uint256) {
        return s_startTimestamp;
    }

    /**
     * @notice Get the value of rewards of the actual lottery
     * @return lotteryBalance Lottery Balance
     */
    function getActualLotteryBalance() external view returns (uint256) {
        return s_lotteryBalance[s_lotteryNumber];
    }

    /**
     * @notice Get the value of rewards of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return lotteryBalance Lottery Balance
     */
    function getLotteryBalance(
        uint256 _lotteryNumber
    ) external view returns (uint256) {
        return s_lotteryBalance[_lotteryNumber];
    }

    /**
     * @notice Get the winning ticket of a specific lottery
     * @param _lotteryNumber The number of the lottery
     * @return winningTicket Lottery winning ticket
     */
    function getWinningTicket(
        uint256 _lotteryNumber
    ) external view returns (uint256[NUM_WORDS] memory) {
        return s_winningTicket[_lotteryNumber];
    }

    /**
     * @notice Get the user pending rewards of his winning lotteries
     * @param _user address of the user
     * @return rewardsBalance Rewards balance
     */
    function getUserRewardsBalance(
        address _user
    ) external view returns (uint256) {
        return s_rewardsBalance[_user];
    }
}

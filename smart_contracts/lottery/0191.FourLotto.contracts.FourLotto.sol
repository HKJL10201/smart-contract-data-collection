//SPDX-License-Identifier: MIT

/* pragma statement */
pragma solidity ^0.8.7;

/* import statements */
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/* custom errors */
error FourLotto__OnlyOwnerCanCallThisFunction();
error FourLotto__NoFunctionCalled();
error FourLotto__UnknownFunctionCalled();
error FourLotto__FourLottoNotOpen();
error FourLotto__InvalidBet(string invalidBet);
error FourLotto__NumberAlreadyTaken(string currentNumber);
error FourLotto__SendMoreToFundBet(uint256 ethAmountRequired);
error FourLotto__PlayerHasAlreadyEntered(string betPlacedByPlayer);
error FourLotto__UpkeepNotNeeded(
    uint256 FourLottoState,
    uint256 numPlayers,
    uint256 currentBalance
);
error FourLotto__ReentrancyDetected();
error FourLotto__PaymentToFirstPlaceWinnerFailed(address payable addressOfFirstPlaceWinner);
error FourLotto__PaymentToSecondPlaceWinnerFailed(address payable addressOfSecondPlaceWinner);
error FourLotto__PaymentToThirdPlaceWinnerFailed(address payable addressOfThirdPlaceWinner);
error FourLotto__PaymentToConsolationWinnerFailed(address payable addressOfConsolationWinner);
error FourLotto__TaxToOwnerFailed();
error FourLotto__WithdrawToOwnerFailed();
error FourLotto__DistributionToCurrentPlayersFailed(address payable addressOfCurrentPlayer);
error FourLotto__NoPotAndThereforeNoNeedToCloseFourLotto();
error FourLotto__FourLottoAlreadyOperating();
error FourLotto__UnableToRemoveHistory(uint256 drawNumber);
error FourLotto__DrawDidNotOccur(uint256 drawNumber);

/** @title FourLotto lottery smart contract
 *  @author Aesthetyx
 *  @notice This contract is for creating an untamperable decentralised smart contract lottery inspired by the 4D lottery in Singapore
 *  @dev This implements Chainlink VRF v2 to obtain random numbers that will be used to determine the winning number, and Chainlink Keepers to automatically draw a winning number periodically

 */

contract FourLotto is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* type declarations */
    enum FourLottoState {
        OPEN,
        CALCULATING,
        PAYING,
        PAUSING,
        PAUSED
    }

    /* state variables */
    // chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 5;
    uint32 private constant NUM_WORDS = 41;

    // FourLotto operation variables
    address payable private immutable i_owner;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_betFee;
    uint256 private s_drawNumber = 1;
    FourLottoState private s_fourLottoState;

    // player and bet management variables
    mapping(uint256 => address payable[]) s_players;
    mapping(uint256 => string[]) s_bets;
    struct Details {
        bool isValid;
        string bet;
        address payable playerAddress;
    }
    mapping(bytes32 => Details) s_betDetails;
    mapping(bytes32 => Details) s_playerDetails;

    // winning number variables
    string[] private s_recentWinningNumbers;
    address payable[] private s_recentFirstPlaceWinner;
    address payable[] private s_recentSecondPlaceWinners;
    address payable[] private s_recentThirdPlaceWinners;
    address payable[] private s_recentConsolationWinners;
    uint256[][] private s_winningNumbersOrderArray = [
        [1, 2, 3, 4],
        [1, 2, 4, 3],
        [1, 3, 2, 4],
        [1, 3, 4, 2],
        [1, 4, 2, 3],
        [1, 4, 3, 2],
        [2, 1, 3, 4],
        [2, 1, 4, 3],
        [2, 3, 1, 4],
        [2, 3, 4, 1],
        [2, 4, 1, 3],
        [2, 4, 3, 1],
        [3, 1, 2, 4],
        [3, 1, 4, 2],
        [3, 2, 1, 4],
        [3, 2, 4, 1],
        [3, 4, 1, 2],
        [3, 4, 2, 1],
        [4, 1, 2, 3],
        [4, 1, 3, 2],
        [4, 2, 1, 3],
        [4, 2, 3, 1],
        [4, 3, 1, 2],
        [4, 3, 2, 1]
    ];

    /* events */
    event FourLottoEntered(string indexed playerBet, address indexed player);
    event WinningNumberRequested(uint256 indexed requestId);
    event DrawCompleted(string[] indexed recentWinningNumbers);

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FourLotto__OnlyOwnerCanCallThisFunction();
        _;
    }

    /* functions */
    // constructor
    constructor(
        address payable ownerAddress,
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 betFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_owner = ownerAddress;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_betFee = betFee;
        s_fourLottoState = FourLottoState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    // receive function
    receive() external payable {
        revert FourLotto__NoFunctionCalled();
    }

    // fallback function
    fallback() external payable {
        revert FourLotto__UnknownFunctionCalled();
    }

    // public functions
    function enterFourLotto(string memory _playerBet) public payable {
        // consider if there is a need for an additional enum to prevent a scenario where players bet on the same numbers at the same instant

        // revert if FourLotto lottery is calculating or closed
        if (s_fourLottoState != FourLottoState.OPEN) {
            revert FourLotto__FourLottoNotOpen();
        }
        // revert if non four digit number is entered by player
        if (bytes(_playerBet).length != 4) {
            revert FourLotto__InvalidBet(_playerBet);
        }
        // revert if number has already been bet on by another player or if player has already placed a bet for current draw
        if (getCurrentBetDetails(_playerBet).isValid == true) {
            revert FourLotto__NumberAlreadyTaken(_playerBet);
        }
        // revert if player has already placed a bet for current draw
        if (getCurrentPlayerDetails(msg.sender).isValid == true) {
            revert FourLotto__PlayerHasAlreadyEntered(getCurrentPlayerDetails(msg.sender).bet);
        }
        // revert if insufficient ETH is transferred to fund bet
        if (msg.value < i_betFee) {
            revert FourLotto__SendMoreToFundBet(i_betFee);
        }

        // first player who places a bet each draw will determine when the three day period begins
        if (getNumberOfCurrentPlayers() == 0) {
            s_lastTimeStamp = block.timestamp;
        }

        // store player and bet in list of players and bets
        uint256 drawNumber = s_drawNumber;
        s_players[drawNumber].push(payable(msg.sender));
        s_bets[drawNumber].push(_playerBet);

        // store player and bet in mappings
        bytes32 betMappingKey = keccak256(abi.encode(drawNumber, _playerBet));
        s_betDetails[betMappingKey] = Details(true, _playerBet, payable(msg.sender));
        bytes32 playerMappingKey = keccak256(abi.encode(drawNumber, msg.sender));
        s_playerDetails[playerMappingKey] = Details(true, _playerBet, payable(msg.sender));

        // emit FourLottoEntered event
        emit FourLottoEntered(_playerBet, msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes calls.
     * they look for `upkeepNeeded` to return true.
     * the following should be true for upkeepNeeded to return true:
     * 1. The time interval has passed between FourLotto draws.
     * 2. FourLotto is open.
     * 3. The contract has ETH balance (and has players).
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (s_fourLottoState == FourLottoState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players[s_drawNumber].length > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers);
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert FourLotto__UpkeepNotNeeded(
                uint256(s_fourLottoState),
                s_players[s_drawNumber].length,
                address(this).balance
            );
        }
        s_fourLottoState = FourLottoState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit WinningNumberRequested(requestId); // here for the purpose of conducting unit tests
    }

    /**
     * @dev This is the function that Chainlink VRF node calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // block of code to prevent re-entrancy
        if (s_fourLottoState != FourLottoState.CALCULATING) {
            revert FourLotto__ReentrancyDetected();
        }
        s_fourLottoState = FourLottoState.PAYING;
        // reset previous winning numbers
        s_recentWinningNumbers = new string[](0);
        // determine winning numbers
        uint256[] memory orderOfWinningNumber = s_winningNumbersOrderArray[(randomWords[0] % 24)];
        for (uint256 i = 0; i < 10; i++) {
            string memory winningNumber = string(
                abi.encodePacked(
                    Strings.toString(randomWords[(orderOfWinningNumber[0] + (i * 4))] % 10),
                    Strings.toString(randomWords[(orderOfWinningNumber[1] + (i * 4))] % 10),
                    Strings.toString(randomWords[(orderOfWinningNumber[2] + (i * 4))] % 10),
                    Strings.toString(randomWords[(orderOfWinningNumber[3] + (i * 4))] % 10)
                )
            );
            // save winning numbers into array
            s_recentWinningNumbers.push(winningNumber);
        }

        // identify and pay winnings to winners, and transfer tax to owner
        string[] memory recentWinningNumbers = s_recentWinningNumbers;
        uint256 currentPot;
        // limit total available winnings to 100ETH to prevent gaming the lottery
        if (address(this).balance > 1e20) {
            currentPot = 1e20;
        } else {
            currentPot = address(this).balance;
        }
        uint256 drawNumber = s_drawNumber;
        address payable owner = i_owner;
        // first place (1 winner) - 40% before tax
        //reset s_recentFirstPlaceWinner
        s_recentFirstPlaceWinner = new address payable[](0);
        if (
            s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[0]))].isValid == true
        ) {
            // save address of first place winner into s_recentFirstPlaceWinner
            s_recentFirstPlaceWinner.push(
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[0]))]
                    .playerAddress
            );
            // pay first place winner
            (bool playerCallSuccess, ) = s_recentFirstPlaceWinner[0].call{
                value: ((currentPot * 40 * 95) / 100) / 100
            }("");
            if (!playerCallSuccess) {
                revert FourLotto__PaymentToFirstPlaceWinnerFailed(s_recentFirstPlaceWinner[0]);
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 40 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }

        // second place (2 winners) - 30% before tax
        // reset s_recentSecondPlaceWinners
        s_recentSecondPlaceWinners = new address payable[](0);
        for (uint256 i = 1; i < 3; i++) {
            if (
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))].isValid ==
                true
            ) {
                s_recentSecondPlaceWinners.push(
                    s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))]
                        .playerAddress
                );
            }
        }
        address payable[] memory recentSecondPlaceWinners = s_recentSecondPlaceWinners;
        // pay second place winners
        if (recentSecondPlaceWinners.length > 0) {
            for (uint256 i = 0; i < recentSecondPlaceWinners.length; i++) {
                (bool playerCallSuccess, ) = recentSecondPlaceWinners[i].call{
                    value: ((currentPot * 30 * 95) / 100) / 100 / recentSecondPlaceWinners.length
                }("");
                if (!playerCallSuccess) {
                    revert FourLotto__PaymentToSecondPlaceWinnerFailed(recentSecondPlaceWinners[i]);
                }
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 30 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }

        // third place (3 winners) - 20% before tax
        // reset s_recentThirdPlaceWinners
        s_recentThirdPlaceWinners = new address payable[](0);
        for (uint256 i = 3; i < 6; i++) {
            if (
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))].isValid ==
                true
            ) {
                s_recentThirdPlaceWinners.push(
                    s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))]
                        .playerAddress
                );
            }
        }
        address payable[] memory recentThirdPlaceWinners = s_recentThirdPlaceWinners;
        // pay third place winners
        if (recentThirdPlaceWinners.length > 0) {
            for (uint256 i = 0; i < recentThirdPlaceWinners.length; i++) {
                (bool playerCallSuccess, ) = recentThirdPlaceWinners[i].call{
                    value: ((currentPot * 20 * 95) / 100) / 100 / recentThirdPlaceWinners.length
                }("");
                if (!playerCallSuccess) {
                    revert FourLotto__PaymentToThirdPlaceWinnerFailed(recentThirdPlaceWinners[i]);
                }
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 20 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }

        // consolation (4 winners) - 10% before tax
        // reset s_recentConsolationWinners
        s_recentConsolationWinners = new address payable[](0);
        for (uint256 i = 6; i < 10; i++) {
            if (
                s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))].isValid ==
                true
            ) {
                s_recentConsolationWinners.push(
                    s_betDetails[keccak256(abi.encode(drawNumber, recentWinningNumbers[i]))]
                        .playerAddress
                );
            }
        }
        address payable[] memory recentConsolationWinners = s_recentConsolationWinners;
        // pay consolation winners
        if (recentConsolationWinners.length > 0) {
            for (uint256 i = 0; i < recentConsolationWinners.length; i++) {
                (bool playerCallSuccess, ) = recentConsolationWinners[i].call{
                    value: ((currentPot * 10 * 95) / 100) / 100 / recentConsolationWinners.length
                }("");
                if (!playerCallSuccess) {
                    revert FourLotto__PaymentToThirdPlaceWinnerFailed(recentConsolationWinners[i]);
                }
            }
            // pay tax to owner
            (bool ownerCallSuccess, ) = owner.call{value: ((currentPot * 10 * 5) / 100) / 100}("");
            if (!ownerCallSuccess) {
                revert FourLotto__TaxToOwnerFailed();
            }
        }
        // +1 to s_drawNumber to "reset" all mappings
        s_drawNumber++;
        // set time of last draw to current time
        s_lastTimeStamp = block.timestamp;
        // set FourLotto back to open so players can once again join FourLotto
        s_fourLottoState = FourLottoState.OPEN;
        // emit DrawCompleted event
        emit DrawCompleted(recentWinningNumbers);
    }

    function pauseFourLotto() public onlyOwner {
        // block of code to prevent re-entrancy
        if (s_fourLottoState != FourLottoState.OPEN) {
            revert FourLotto__FourLottoNotOpen();
        }
        s_fourLottoState = FourLottoState.PAUSING;

        if (address(this).balance > 0) {
            address payable[] memory players = s_players[s_drawNumber];
            uint256 betFee = i_betFee;
            // refund all current players for bets placed
            for (uint256 i = 0; i < players.length; i++) {
                (bool playerCallSuccess, ) = players[i].call{value: betFee}("");
                if (!playerCallSuccess) {
                    revert FourLotto__DistributionToCurrentPlayersFailed(players[i]);
                }
            }
            // remainder extracted to owner
            (bool ownerCallSuccess, ) = i_owner.call{value: address(this).balance}("");
            if (!ownerCallSuccess) {
                revert FourLotto__WithdrawToOwnerFailed();
            }
            // +1 to s_drawNumber to "reset" all mappings
            s_drawNumber++;
            // set time of closure to current time
            s_lastTimeStamp = block.timestamp;
            // set FourLotto to paused so that players can no longer enter
            s_fourLottoState = FourLottoState.PAUSED;
        } else {
            revert FourLotto__NoPotAndThereforeNoNeedToCloseFourLotto();
        }
    }

    function resumeFourLotto() public onlyOwner {
        if (s_fourLottoState == FourLottoState.PAUSED) {
            s_fourLottoState = FourLottoState.OPEN;
        } else {
            revert FourLotto__FourLottoAlreadyOperating();
        }
        s_lastTimeStamp = block.timestamp;
    }

    // gas cost of removeHistoryOfAPastDraw is too high, but left here while figuring out how to lower gas cost
    // function removeHistoryOfAPastDraw(uint256 _drawNumber) public onlyOwner {
    //     if (_drawNumber >= s_drawNumber) {
    //         revert FourLotto__UnableToRemoveHistory(_drawNumber);
    //     }
    //     if (_drawNumber < 1) {
    //         revert FourLotto__DrawDidNotOccur(_drawNumber);
    //     }
    //     string[] memory bets = s_bets[_drawNumber];
    //     address payable[] memory players = s_players[_drawNumber];
    //     delete s_bets[_drawNumber];
    //     delete s_players[_drawNumber];
    //     for (uint256 i = 0; i < bets.length; i++) {
    //         delete s_betDetails[keccak256(abi.encode(_drawNumber, bets[i]))];
    //         delete s_playerDetails[keccak256(abi.encode(_drawNumber, players[i]))];
    //     }
    // }

    // view / pure functions
    // chainlink VRF variables
    function getVRFCoordinator() public view returns (VRFCoordinatorV2Interface) {
        return i_vrfCoordinator;
    }

    // KIV, unhide for the time being
    function getSubscriptionId() public view returns (uint64) {
        return i_subscriptionId;
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getRequestConfirmations() public pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumWords() public pure returns (uint32) {
        return NUM_WORDS;
    }

    // FourLotto operation variables
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getBetFee() public view returns (uint256) {
        return i_betFee;
    }

    function getCurrentDrawNumber() public view returns (uint256) {
        return s_drawNumber;
    }

    function getFourLottoState() public view returns (FourLottoState) {
        return s_fourLottoState;
    }

    // pot size and lottery balance
    function getFourLottoBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentPot() public view returns (uint256) {
        uint256 currentPot;
        if (address(this).balance > 1e20) {
            currentPot = 1e20;
        } else (currentPot = address(this).balance);
        return currentPot;
    }

    function getPotentialFirstPlaceWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialFirstPlaceWinnings = (currentPot * 40 * 95) / 100 / 100;
        return potentialFirstPlaceWinnings;
    }

    function getPotentialSecondPlaceWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialSecondPlaceWinnings = (currentPot * 30 * 95) / 100 / 100;
        return potentialSecondPlaceWinnings;
    }

    function getPotentialThirdPlaceWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialThirdPlaceWinnings = (currentPot * 20 * 95) / 100 / 100;
        return potentialThirdPlaceWinnings;
    }

    function getPotentialConsolationWinnings() public view returns (uint256) {
        uint256 currentPot = getCurrentPot();
        uint256 potentialConsolationeWinnings = (currentPot * 10 * 95) / 100 / 100;
        return potentialConsolationeWinnings;
    }

    // player and bet management variables
    // KIV, unhide for the time being
    function getCurrentPlayers() public view returns (address payable[] memory) {
        return s_players[s_drawNumber];
    }

    function getNumberOfCurrentPlayers() public view returns (uint256) {
        return s_players[s_drawNumber].length;
    }

    // KIV, hidden for the time being
    // function getPastPlayers(uint256 _drawNumber) public view returns (address payable[] memory) {
    //     return s_players[_drawNumber];
    // }

    // KIV, unhide for the time being
    function getCurrentBets() public view returns (string[] memory) {
        return s_bets[s_drawNumber];
    }

    function getNumberOfCurrentBets() public view returns (uint256) {
        return s_bets[s_drawNumber].length;
    }

    // KIV, hidden for the time being
    // function getPastBets(uint256 _drawNumber) public view returns (string[] memory) {
    //     return s_bets[_drawNumber];
    // }

    function getCurrentPlayerDetails(address _playerAddress) public view returns (Details memory) {
        bytes32 key = keccak256(abi.encode(s_drawNumber, _playerAddress));
        return s_playerDetails[key];
    }

    // KIV, hidden for the time being
    // function getPastPlayerDetails(uint256 _drawNumber, address _playerAddress)
    //     public
    //     view
    //     returns (Details memory)
    // {
    //     bytes32 key = keccak256(abi.encode(_drawNumber, _playerAddress));
    //     return s_playerDetails[key];
    // }

    function getCurrentBetDetails(string memory _bet) public view returns (Details memory) {
        bytes32 key = keccak256(abi.encode(s_drawNumber, _bet));
        return s_betDetails[key];
    }

    // KIV, hidden for the time being
    // function getPastBetDetails(uint256 _drawNumber, string memory _bet)
    //     public
    //     view
    //     returns (Details memory)
    // {
    //     bytes32 key = keccak256(abi.encode(_drawNumber, _bet));
    //     return s_betDetails[key];
    // }

    // winning number variables
    function getRecentWinningNumbers() public view returns (string[] memory) {
        return s_recentWinningNumbers;
    }

    function getRecentFirstPlaceWinner() public view returns (address payable[] memory) {
        return s_recentFirstPlaceWinner;
    }

    function getRecentSecondPlaceWinners() public view returns (address payable[] memory) {
        return s_recentSecondPlaceWinners;
    }

    function getRecentThirdPlaceWinners() public view returns (address payable[] memory) {
        return s_recentThirdPlaceWinners;
    }

    function getRecentConsolationWinners() public view returns (address payable[] memory) {
        return s_recentConsolationWinners;
    }

    function getWinningNumbersOrderArray() public view returns (uint256[][] memory) {
        return s_winningNumbersOrderArray;
    }
}

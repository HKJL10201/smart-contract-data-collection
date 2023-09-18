// Rafle

// Enter the lottery (paying some amount)

// Pick a random winner

// Winner to be selected automated

// Chainlil Oracle --> Randomness, Automated Execution

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

pragma solidity ^0.8.18;

error EnterLottery__NotEnoughEntryPrice();
error EnterLottery__AlreadyParticipated();
error Lottery__TransferFailed();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers);
error GodMode__OnlyOwner();
error Lottery__IsNotActive();
error GetYourId__IdIsNotValid();

/** @title A Sample Lottery Contract
 * @author Ali Eray
 * @notice This contract is for creating decentralized lottery smart contract
 * @dev This implements Chainlik VRF v2 and Chainlik Keepers
 */

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    mapping(uint256 => mapping(address => bool)) public lotteryIdToCandidates;
    mapping(uint256 => mapping(uint256 => address)) public lotteryToTicketIdToAddress;
    mapping(address => mapping(uint => uint)) addressTolotteryIdToTicketId;
    mapping(address => mapping(uint => bool)) isAddressInLottery;

    // State variables

    uint256 private i_entryPrice;
    uint256 private lotteryId;
    uint256 private bonusAmount;
    uint256 private ticketIdCounter;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint16 private immutable i_requestConfirmation;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable i_numWords;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    address private immutable i_owner;
    address recentWinner;
    bool private isActive = true;

    // Events
    event LotteryEnter(address indexed candidate, uint256 indexed ticketIdCounter);
    event IdRequest(uint256 indexed requestId);
    event WinnerSelected(
        address indexed winner,
        uint256 indexed lotteryId,
        uint256 indexed ticketId
    );

    constructor(
        address vrfCoordinatorV2,
        uint256 entryPrice,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmation,
        uint32 callbackGasLimit,
        uint32 numWords,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entryPrice = entryPrice;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_requestConfirmation = requestConfirmation;
        i_callbackGasLimit = callbackGasLimit;
        i_numWords = numWords;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
        i_owner = msg.sender;
    }

    function godMode() public {
        if (i_owner != msg.sender) {
            revert GodMode__OnlyOwner();
        }
        isActive = !isActive;
    }

    function enterLottery() public payable {
        if (!isActive) {
            revert Lottery__IsNotActive();
        }
        if (lotteryIdToCandidates[lotteryId][msg.sender] == true) {
            revert EnterLottery__AlreadyParticipated();
        }
        if (msg.value != i_entryPrice) {
            revert EnterLottery__NotEnoughEntryPrice();
        }
        ticketIdCounter++;

        lotteryIdToCandidates[lotteryId][msg.sender] = true;
        lotteryToTicketIdToAddress[lotteryId][ticketIdCounter] = msg.sender;
        addressTolotteryIdToTicketId[msg.sender][lotteryId] = ticketIdCounter;
        isAddressInLottery[msg.sender][lotteryId] = true;

        bonusAmount += msg.value;
        emit LotteryEnter(msg.sender, ticketIdCounter);
    }

    /**
     * @dev Chainlink Keeper
     * Some requirements needed
     * 1. correct time
     * 2. at least 1 person
     * 3. subscription fund with Link
     * 4. lottert should be open
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public override returns (bool upkeepNeeded, bytes memory performData) {
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (ticketIdCounter > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && hasPlayers && hasBalance && isActive);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (!isActive) {
            revert Lottery__IsNotActive();
        }
        // We will just get a random number which will be winner tickedId
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(address(this).balance, ticketIdCounter);
        }
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmation,
            i_callbackGasLimit,
            i_numWords
        );
        emit IdRequest(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (!isActive) {
            revert Lottery__IsNotActive();
        }
        uint256 winnerTicketId = (randomWords[0] % (ticketIdCounter)) + 1;

        recentWinner = lotteryToTicketIdToAddress[lotteryId][winnerTicketId];
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        ticketIdCounter = 1;
        lotteryId++;
        s_lastTimeStamp = block.timestamp;
        emit WinnerSelected(recentWinner, lotteryId, ticketIdCounter);
    }

    function drawLottery() public {
        if (i_owner != msg.sender) {
            revert GodMode__OnlyOwner();
        }
        uint256[] memory randomWords = getRandomWordsMock();

        fulfillRandomWords(0, randomWords);
    }

    function getRandomWordsMock() internal returns (uint256[] memory) {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] =
            uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) %
            1000;
        return randomWords;
    }

    function getMoneyOnlyOwner() public {
        if (i_owner != msg.sender) {
            revert GodMode__OnlyOwner();
        }
        (bool sent, ) = i_owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function getEntryPrice() public view returns (uint256) {
        return i_entryPrice;
    }

    function getLotteryId() public view returns (uint256) {
        return lotteryId;
    }

    function getPlayer(uint256 _lotteryId, uint256 _ticketId) public view returns (address) {
        return lotteryToTicketIdToAddress[_lotteryId][_ticketId];
    }

    function getNumberOfPlayer() public view returns (uint256) {
        return ticketIdCounter;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function isContractActive() public view returns (bool) {
        return isActive;
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getYourId() public view returns (uint) {
        if (!isAddressInLottery[msg.sender][lotteryId]) {
            revert GetYourId__IdIsNotValid();
        }
        return addressTolotteryIdToTicketId[msg.sender][lotteryId];
    }
}

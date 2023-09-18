pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 s_keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;
    address s_owner;

    // map rollers to requestIds
    mapping(uint256 => address) private s_rollers;
    // map vrf results to rollers
    mapping(address => uint256) private s_results;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    // uint8 fee;
    // bool lotteryStatus = false;
    address public manager;
    // address[] public players;
    // uint minimumEnteringAmount;

    struct LotteryInfo {
        uint8 fee;
        bool lotteryStatus;
        address winner;
        uint minimumEnteringAmount;
        uint totalDeposit;
        mapping(address => uint) enteredAmount;
        LotteryPlayerInfo lotteryPlayer;
    }

    struct LotteryPlayerInfo {
        address player;
        uint enteredAmount;
    }

    LotteryInfo[] public lotteryInfo;

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier activeLottery() {
        require(lotteryStatus == true, "Lottery not started yet");
        _;
    }

    event Fund(address indexed participant, uint amount);
    event Winner(address indexed winner, uint winningAmount);

    constructor(
        uint64 subscriptionId,
        address _manager
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        manager = msg.sender;
    }

    function startLottery(
        uint _lotteryId,
        uint _feePercent,
        uint _minimumEnteringAmount
    ) public onlyManager {
        require(
            lotteryInfo[_lotteryId].lotteryStatus == false,
            "Lottery already started"
        );
        fee = _feePercent;
        minimumEnteringAmount = _minimumEnteringAmount;
        lotteryStatus = true;
    }

    function enterLottery() public payable activeLottery {
        require(
            msg.value > lotteryInfo[_lotteryId].minimumEnteringAmount,
            "Minimum entering amount not passed"
        );
        lotteryInfo[_lotteryId].push(msg.sender);
        emit Fund(msg.sender, msg.value);
    }

    /**
     * @notice Requests randomness
     * @dev Warning: if the VRF response is delayed, avoid calling requestRandomness repeatedly
     * as that would give miners/VRF operators latitude about which VRF response arrives first.
     * @dev You must review your implementation details with extreme care.
     *
     * @param roller address of the roller
     */
    function rollDice(
        address roller
    ) public onlyOwner returns (uint256 requestId) {
        require(s_results[roller] == 0, "Already rolled");
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_rollers[requestId] = roller;
        s_results[roller] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, roller);
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number to this contract.
     *
     * @dev Some action on the contract state should be taken here, like storing the result.
     * @dev WARNING: take care to avoid having multiple VRF requests in flight if their order of arrival would result
     * in contract states with different outcomes. Otherwise miners or the VRF operator would could take advantage
     * by controlling the order.
     * @dev The VRF Coordinator will only send this function verified responses, and the parent VRFConsumerBaseV2
     * contract ensures that this method only receives randomness from the designated VRFCoordinator.
     *
     * @param requestId uint256
     * @param randomWords  uint256[] The random result returned by the oracle.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 d20Value = (randomWords[0] % 20) + 1;
        s_results[s_rollers[requestId]] = d20Value;
        emit DiceLanded(requestId, d20Value);
    }

    /**
     * @notice Get the house assigned to the player once the address has rolled
     * @param player address
     * @return house as a string
     */
    function house(address player) public view returns (string memory) {
        require(s_results[player] != 0, "Dice not rolled");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        return getHouseName(s_results[player]);
    }

    /**
     * @notice Get the house namne from the id
     * @param id uint256
     * @return house name string
     */
    function getHouseName(uint256 id) private pure returns (string memory) {
        string[20] memory houseNames = [
            "Targaryen",
            "Lannister",
            "Stark",
            "Tyrell",
            "Baratheon",
            "Martell",
            "Tully",
            "Bolton",
            "Greyjoy",
            "Arryn",
            "Frey",
            "Mormont",
            "Tarley",
            "Dayne",
            "Umber",
            "Valeryon",
            "Manderly",
            "Clegane",
            "Glover",
            "Karstark"
        ];
        return houseNames[id - 1];
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    // function random() private view returns (uint) {
    //     return uint(keccak256(block.difficulty, now, players));
    // }

    // function pickWinner() public onlyManager {
    //     uint index = random() % players.length;
    //     uint winningAmount = this(address).balance;
    //     players[index].transfer(winningAmount);
    //     emit Winner(players[index], winningAmount)
    //     players = new address[](0);
    // }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}

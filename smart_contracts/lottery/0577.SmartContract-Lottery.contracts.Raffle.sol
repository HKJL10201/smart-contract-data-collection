// Raffle contract must allow us to :
//Enter the lottery (paying some gas fees)
//pick a random winner (verifiably random : untamperable)
// winner to be selected every x minutes, hours...---> completly automated

//chainlink oracle ----> randomness, event driven :
// we need to get the randomness outsite the blockchain
//autpmated execution :: smart contract can't execute itself (chainlink keeper)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";// npm install @chainlink/contracts
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";




error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface{
    // Raffle contract must inherit from the vrfconsumerbasev2 contract
    /* type déclarations */
    // create new type:
    enum RaffleState {
        OPEN,
        CALCULATING  
    }
    // RaffleState it return 0 if it "OPEN" else 1
    //uint256 0 = OPEN , 1 = CALCULATING

    /* state variables */
    address payable[] private s_players; // if a player win we need to pay him
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /* Lottery variables*/
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp; // this allow us to calculate the interval
    uint256 private immutable i_interval;

    /* chainlink vrf variables*/
     VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    /* events */
    event Raffleenter(address player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player);

    /* functions */
    constructor(address vrfCoordinatorV2, uint256 entranceFee, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit, uint256 interval) VRFConsumerBaseV2(vrfCoordinatorV2){
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;


    }
    function enterRaffle () public payable{
        // require(msg.value > i_entranceFee, "not enough ETH") : this will store a sting("not enough eth")
        if(msg.value < i_entranceFee){revert Raffle__NotEnoughETHEntered();}
        if(s_raffleState != RaffleState.OPEN){revert Raffle__NotOpen();}
        s_players.push(payable(msg.sender));
        // emit an event when we update a dynamic array or mapping
        // events get emitted to a data storage outside of the smart contract
        // named events with the function name revesed
        emit Raffleenter(msg.sender);
    }
    /**
     * @dev This is the function that the chainlink keeper nodes call
     * they look for the upkeepNeeded to rturn true
     * the following should be true in order to return true
     * 1- our time interval should have passed
     * 2- the lottery should have at least 1 player, and have some ETH
     * 3- our subscription is funded with Link
     * 4- the lottery shoud be in an open state
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
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    //chainlink VRF
    // external : can be called from other contracts and not by the current contract
    function performUpkeep(
        bytes calldata /* performData */
    ) external{
        // calldata doesnt work with string;
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        // request random number
        // once we get it, do something with it
        // chainlink VRF is = two transactions process
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,// keyHash = gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS // how many random words we want to get
        );
        // this is redundent: requestRandomWords emits an event 
        emit RequestedRaffleWinner(requestId);
    }
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override {
    // fulfillrandomwords() is virtual so its expected to be overriden
      uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
         (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
      
    }

    /* view and pure functions */
    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }
    function getPlayer(uint256 index)public view returns(address){
        return s_players[index];
    }
    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }
    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }
    function getNumWords() public pure returns (uint256) {
        // num_words is constant, so wa are not reading from storage : 
        //so wa can make it pure function
        return NUM_WORDS;
    }
    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
     function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
    function getInterval() public view returns (uint256){
        return i_interval;
    }
}
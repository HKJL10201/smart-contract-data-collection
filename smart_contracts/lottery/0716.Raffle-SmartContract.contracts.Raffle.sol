//raffle (selling tickets)
//enter the lottery (paying some amount)
//pick a random number (verifiably random, i. e. no cheating) (using chainlink oracle)
//winner to be selected every X minutes -> completely automated(using chailink keeper)

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//need to refer to https://docs.chain.link/docs/get-a-random-number/ or this code's github repo to learn its working for vrf
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//interface required to interact with vrfcoordinator contract
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//importing interfaces required to run chainlink keeper
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
//for this, need to install @chainlink via yarn add --dev @chainlink/contracts

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/** @title A sample Raffle Contract
@author Yukta Saneja
@notice This contract is for creating an untamperable smart contract
@dev this implements Chainlink VRF and Chainlink Keepers
 */

//need to inherit vrf consumerbase and keeper compatible interface(to be able to run checkupkeep and performupkeep fns)
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /**to define states, bool only gives 2 options, true/false, uint256 is tiresome, enum is best->essentially like uint256
    enum is like creating a new type, and types come at top */

    /**Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING //to store state when waiting for random no. to arrive, we dont wanna perform keep while that
        //similar to uint256 0=OPEN, 1=CALCULATING
    }
    /**State variables */

    //always mention visibility
    //to save gas, make storage var, entrancefee as immutable as we only set it once, later in the constructor
    uint256 private immutable i_entranceFee;
    //need to store each enetered player, and so keep updating so cant be immutable, has to be storage
    address payable[] private s_players; //players are payable, bec we need to make tx to send money to winner player later out of this array
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /**Lottery variables */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /**EVENTS */
    /** events are emitted and listened, they get stored in logs which is a data structure which doesnt cost gas
    but stores some data, so efficient, events take parameters of 2 types-indexed(easier to find, dont need abi to decode),
    and non indexed(need abi to decode but cost less gas). if ur contract is verified, it can be visible non indexed using
    dec output in logs of contracts, otherwise in hex, indexed are always available */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /**functions */
    //the vrf consumerbase also takes a contructor param, so need to take it as a param and pass it to vrf
    //vrfcoordinator address connects us to the node where chainlink vrf is running
    constructor(
        address vrfCoordinatorV2, //will require mocks while deploying
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId, //it will be smaller so no need of uint256
        uint32 callbackGasLimit,
        uint256 interval //to set interval for checking in keeper
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN; //or RaffleState(0)
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        //using revert instead of require to save gas
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            //becoz not letting new entry while not open
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        //emit an event everytime an array or map is updated
        //name the events with function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
@dev this is the fn that chainlink keepers node call and wait for 'upKeepNeeded' to return true
the f/w should be true in order to return true:
1.our time interval shud have passed
2. lottery shud have at least 1 player and have some eth
3.our subscription is funded with LINK
4. lottery shud be in an open state
 */
    function checkUpkeep(
        bytes memory /*checkData*/ //notexternal cuz we wanna call it too, not calldata as it dsnt take strings, so make it memory
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData, use to specify 
    if checkupkeep need to do smthin else*/
        )
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        //to keep track of time intervals, do current block timestamp(using block.timestamp)-last block timestamp(will need a state var)
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance); //when it is true, automatically performupkeep is called
    }

    //pick random winner, will need chainlink vrf and chainlink keeper
    //read about chainlink vrf in original code in its github repo (provided link in course repo) or in chainlink vrf docs
    //external functions are cheaper than public as they know that external functions cant be called by own contract
    function performUpkeep(
        bytes calldata /**perfrm data */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance, //to warn in case not enough balance
                s_players.length, //in case no players
                uint256(s_raffleState) //in case lottery not open yet
            );
        }
        //request random no. once we get it, do somthing with it
        //so 2 transaction process, this also avoid manupilating of fn to try and simulate to find random no. by cheater
        s_raffleState = RaffleState.CALCULATING;
        //can check f/w from docs
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //aka gaslane(keyhash), max gas u r willing to pay, needs ip thru contructor
            i_subscriptionId, //id of account who pays for our subscriptions through a contract, need to pass as a param in constructor as well
            REQUEST_CONFIRMATIONS, //no. of block confirmations to wait for before getting response, can make it constant as ot so imp
            i_callbackGasLimit, //limit for huge gas requiring random no. calls to that contract, parameterising
            NUM_WORDS //no. of random words we want,  can be constant as we want only 1
        );
        emit RequestedRaffleWinner(requestId);
    }

    //node modules-chainlink-src-v08-vrfconsumberbasev2-u see the contract, this fn is virtual, hence needs to be overriden
    //also use its same params
    function fulfillRandomWords(
        uint256, /*requestId, we dont use it but it is needed as param for this fn*/
        uint256[] memory randomWords
    ) internal override {
        //random no. generated can be too large, then take its mod, so take mod with no. of ppl in players arr
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp; //resetting time
        s_players = new address payable[](0); //resetting the players array
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    //view/pure functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    //to fetch a particular player from array
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    //is pure fn becoz we arent reading from storage, we r literlly returning number 1
    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}

/**
hardhat has an npm package to autocomplete and write terminal commands shortly(i.e. to replace yarn hardhat etc)
it is hardhat shorthand-> yarn global add hardhat-shorthand
now yarn hardhat compile=hh compile, yarn hardhat=hh
 */

//smart contract lottery
//front end, eth_requrest and allow user to conenct wallet
//deposit function, minimum .1 ethereum to enter lottery
//for every .1 eth deposited, add the msg.sender address to a array to hold all contestents
//use random number from orical to pick random index in contestent array
// send winning eth to address

//want the lottery to run every x hours automatically.

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
//errors use less gas than doing require(~~~~)}
error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__upkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

/**
 * @title Sample Smart Contract Lottery Contract
 * @author Sean Flaherty
 * @notice This contract is for creating a untamperable, decentralized lotterty in the form of a smart contract
 * @dev this implements ChainLink VRf v2 and ChainLink Keepers
 */

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type Declarations */

    enum RaffleState {
        OPEN,
        CALCULATING
    } //secretly calulating new uint 256 where "0" == OPEN, "1" == CALCULATING;

    /* State Vars */
    uint256 private immutable i_entranceFee;
    address payable[] private s_contestentArray;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUMBER_WORDS = 1;

    /* Lottery Vars */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Evnents */

    //addition of new player in array
    event raffleEnter(address indexed player);
    //ping chainlink to get random num
    event requestedRaffleWinner(uint256 indexed requestId);
    //ping front end to show winner
    event winnerPicked(address indexed winner);

    /* constructor */
    constructor(
        address vrfCoordinatorV2, //contract, cant be accessed in non-test net setting, make a mock for this
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        //instead of doing require(msg.sender > i_enterance fee, create custom error to save much more gas)
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_contestentArray.push(payable(msg.sender));
        emit raffleEnter(msg.sender);
        //whenever we update a array or mapping, we want to emit an "event" to our frontend
    }

    /*
     * @dev This is the func that the chainlink keeper nodes call
     * they look for the 'upkeepneeded' to return true.
     * to be true....
     * 1.)our time interval should pass.
     * 2.) lottery must have min 1 player and have some eth
     * 3.) our subscription is funded with link
     * 4.) lottery should be in a "open" state
     * check to see if its time to pick random number. to update recent winner
     */
    function checkUpkeep(
        bytes memory /*checkData */
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /*perform data */)
    {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool playerArray = (s_contestentArray.length >= 1);
        bool timeStamp = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && playerArray && hasBalance && timeStamp);
    }

    function performUpkeep(bytes calldata /*perform data */) external override {
        //request random num fro mcahinlink
        //do something with random num
        // 2 transaction process
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__upkeepNotNeeded(
                address(this).balance,
                s_contestentArray.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMBER_WORDS
        );
        emit requestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_contestentArray.length;
        address payable recentWinner = s_contestentArray[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_contestentArray = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit winnerPicked(recentWinner);
    }

    /* Get Functions */
    function getEnteranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_contestentArray[index];
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUMBER_WORDS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_contestentArray.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmation() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}

// Raffle
// enter the lottery amount
//pick a random winner
//winner to selected every X minutes -> completely automate
//Chainlink Oracle -> Randomness,Automated Execution

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle_NotEnoughEthEntered();
error Raffle_TrasferFailed();
error Raffle_NotOpen();
error Raffle_UpkeepNotNeeded(
    uint256 balance,
    uint256 players,
    uint256 raffleState
);

/** @title A sample raffle smartContract
 * @author Deepak
 * @notice contract to create untemperable decentrilzed smart contract
 * @dev this implements chainlink vrf2 and chainlink keeper to get the random words and run runterval resp.


*/

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /*
     type declarations

     */

    // in enums
    enum RaffleState {
        Open,
        Calculating
    } // decalring this var by default uint256, Open = 0, Calculating  = 1

    // now declare entrance fee
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    // how many confirmations the Chainlink node should wait before responding
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;

    /*limit for how much gas to use for the callback request to your contract's fulfillRandomWords()*/
    uint32 private s_callbackGasLimit;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    /*
     lottery variables
    */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval; // interval required to get the random winner

    /* Events */

    event RaffleEnter(address indexed player);
    event RaffleRequestedWinner(uint256 indexed requestId);
    event winnerPicked(address indexed winnerPicked);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId, // subscription id require short so thats why it is 64 bit
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.Open; // we are considering lottery is open  by default
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            //checking entrance fee is more than enough or not
            revert Raffle_NotEnoughEthEntered();
        }

        // now adding sender into player list who pay sufficeint fund
        if (s_raffleState != RaffleState.Open) {
            revert Raffle_NotOpen();
        }
        s_players.push(payable(msg.sender));

        //emit an event  when sender added in array
        emit RaffleEnter(msg.sender);
    }

    /* so basically 'checkupkeep' just tell us is it time to get us random winner by checking all required parameter and send all eth to winner


        * this is the function that the chainlink keepr nodes call
        * they look for the 'upkeepNeeded' to return true
        *The following should be true in order to return true:
        * 1. Our time interval should have passed.
        * 2. The lottery should have atleast 1 player and have some eth.
        * 3. Our subscription is funded with link.
        * 4. The lottery should be in an open state means lottery is pending ,calculating


    */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upKeepNeeded, bytes memory) {
        // now check lottery in open state first
        bool isOpen = (RaffleState.Open == s_raffleState);

        // now compare time stamp with interval

        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);

        // check atleast player in lottery
        bool hasPlayer = (s_players.length > 0);

        // check balance
        bool hasBalance = (address(this).balance > 0);
        upKeepNeeded = (isOpen && timePassed && hasPlayer && hasBalance); // this boolean value will cause the lottery to be opened and closed. if true it means lottery closed
        return (upKeepNeeded, "0x0"); // can we comment this out?
    }

    /*
      upKeep check all conditon to pick a random winner withing given time interval. if all conditon not met. then raffle entry will be closed,
      then PerfromUpkeep will check if if upKeep function gives true value then it will run its function get the winner 
    
    */

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upKeepNeeded, ) = checkUpkeep("0x");
        if (!upKeepNeeded) {
            // checking Raffle state in closed or opened
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        // update RaffleState into calucalting mod
        s_raffleState = RaffleState.Calculating;

        //request random number
        // once we get it do something with it
        // 2 transaction process
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId, // id that require to fund the request
            REQUEST_CONFIRMATIONS, // confirmations that chainlink node should wait before responding
            s_callbackGasLimit, // how much gas to use for callback request to your contract  fullfillRandomWords()
            NUM_WORDS // number of random values we want to get
        );

        emit RaffleRequestedWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        // lets say random words is 202
        // s_player size is 10 means participants number
        // 202%  10 = 2 which is index number in s_player array will be the winner of lottery

        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        // once we get winner then empty the s_playre to zero
        s_players = new address payable[](0);
        s_recentWinner = recentWinner;

        //after getting winner change rafflestate to open mode
        s_raffleState = RaffleState.Open;

        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // after getting winner send all the value of this contract to this winner
        if (!success) {
            revert Raffle_TrasferFailed();
        }
        emit winnerPicked(recentWinner);
    }

    //read entrance Fee
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint index) public view returns (address) {
        return (s_players[index]);
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNameword() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfplayer() public view returns (uint256) {
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

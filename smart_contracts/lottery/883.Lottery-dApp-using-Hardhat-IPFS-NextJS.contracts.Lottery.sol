// SPDX-License-Identifier: MIT

 //Steps of Lottery App
//  Participate in the lottery by paying some amount
// Pick GENUINELY RANDOM winner
// Winner selected every X minutes = completely automated
// Chainlink Oracle -> Randomness + Automated Execution using Chainlink Keeper






// 14:56:30







pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransferFailed();

/** @title Lottery Contract
    @author Abhiram Satpute
    @notice This contract creates an untamperable, decentralized, NON-automated smart contract
    @dev Implements Chainlink VRFv2
 */

contract Lottery is VRFConsumerBaseV2 {

    //state variables = storage
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant NUM_WORDS = 3;

    // Lottery Variables
    address private s_recentWinner; //start as none, then fill

    // Events
    event participatedEvent(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // Constructor
    constructor(address vrfCoordinatorV2, uint256 entranceFee, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2); //now we can access the random gen contract, this is the address
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    // View / Pure Functions and Getters
    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns(uint256) {
        return s_players.length;
    }

    // Functions
    function lotteryParticipate() public payable {

        if (msg.value < i_entranceFee) {
            // revert the whole transaction using error code
            // so GAS EFFICIENT instead of storing string
            revert Lottery__NotEnoughETHEntered();
        }

        s_players.push(payable(msg.sender));
        // emit and event (both have same name) when we update a dynamic array like s_players
        emit participatedEvent(msg.sender);
    }


    //here we need Chainlink VRF v2 and Keepers
    // Steps: Go to chainlink, connect Metamask wallet, add Goerli Testnet and LINK
    // Create Subscription, Add funds
    // Create Consumer, add consumer contract with address = VRFv2Consumer.sol contract 

    // we call 2 txn process, so remove hackablility, manipulation, etc. if only one txn
    // 1) requestRandomWinner
    // 2) fulfillRandomWords (VRF ki method hai)

    function requestRandomWinner() external { //external are a bit cheaper than PUBLIC functions
        // called by chainlink Keepers automatically (automated)

        // this can be cross checked with the original/template VRF Code
        // of VRFConsumerBaseV2.sol that we imported above
        // also on random generator page on chainlink


        uint256 requestId = i_vrfCoordinator.requestRandomWords( //returns requestId + other related info
            i_keyHash, // max gas willing to pay in gwei, see: https://docs.chain.link/vrf/v2/subscription/supported-networks/
            i_subscriptionId,
            REQUEST_CONFIRMATIONS, // how many blocks to wait for confirmation
            i_callbackGasLimit, //sets GAS limit on fulfillRandomWords's computation
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);



    }

    //here, words still means numbers, so A HUGE SINGLE STRING OF NUMBERS
    // "override" function of THIS CONTRACT <=> "virtual" function of INHERITED CONTRACT
    function fulfillRandomWords(uint256 /*requestId - we will use uint256 but its not requestId explicitly in code*/, uint256[] memory randomWords) internal override {
        // use RandomNumber % numberOfPlayers until we get a single digit from 0-noOfPLayers at the end
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        // paying the winnner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success), or below to be more GAS EFFICIENT
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

}
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//contract_Address = 0xe3B2B7a470cC4b33036Bbe5fd38afa9eEed2C92E
//configrations for vrf system of mumbai teest net
//     vrfcoordinator - 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
//     //subscription - 4528
//     //keyhash- 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
//     //interval - 120
//     //entranceFee - 100
//     //callbackGasLimit - 2,500,000

contract Lottery is VRFConsumerBaseV2 {
    address public manager;
    address payable[] private participants;
    uint public lotteryId;
    mapping(uint => address payable) public lotteryHistory;

    enum State {
        STARTED,
        ENDED
    }
    event RoundOver(string, uint, address payable);

    State private lotteryState;

    // For randomness
    event RandomNumberReceived(string message, uint number);
    VRFCoordinatorV2Interface private COORDINATOR;

    constructor()
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        manager = msg.sender;
        lotteryState = State.STARTED;
        lotteryId = 1;

        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        ); // VRF Coordinator
    }

    receive() external payable {
        require(
            lotteryState == State.STARTED,
            "Lottery is not yet started. Choose a manager first."
        );
        require(msg.sender != manager, "Manager cannot participate");
        require(
            msg.value == 0.01 * 10**18,
            "Must send exactly 0.01 ether to participate"
        );

        if (!alreadyParticipated(msg.sender))
            participants.push(payable(msg.sender));
    }

    function getResults() public {
        require(
            lotteryState == State.STARTED,
            "Lottery is not yet started. Choose a manager first."
        );
        require(msg.sender == manager, "Only manager can get the results");
        require(
            participants.length >= 3,
            "Lottery must have at least 3 participants"
        );

        getRandomNumber(); // You may catch the returned request Id
    }

    function getRandomNumber() private returns (uint requestId) {
        return
            COORDINATOR.requestRandomWords(
                0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f, // keyhash
                4528, // Subscription Id
                3, // Request Confirmations
                2500000, // Callback Gas Limit
                1 // Number of random numbers to be generated
            );
    }

    // This method will be automatically called after getRandomNumber()
    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] memory randomResults
    ) internal override {
        emit RandomNumberReceived(
            "Received a truly random number",
            randomResults[0]
        );

        // Getting the winner
        uint randomIndex = randomResults[0] % participants.length;

        address payable winner = participants[randomIndex];

        // Updating the lottery history
        lotteryHistory[lotteryId] = participants[randomIndex];

        // Resetting the lottery
        manager = address(0);
        participants = new address payable[](0);
        lotteryState = State.ENDED;

        winner.transfer(address(this).balance);

        emit RoundOver(
            "A lottery round has ended. Following are the winning amount (in ether) and the winner: ",
            address(this).balance / 10**18,
            winner
        );
    }

    function setNewManager() public {
        require(
            lotteryState == State.ENDED,
            "Cannot change manager in middle of a lottery"
        );
        manager = msg.sender;
        lotteryState = State.STARTED;
        lotteryId++;
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function getCollectedAmount() public view returns (uint) {
        return address(this).balance;
    }

    function alreadyParticipated(address participant)
        private
        view
        returns (bool)
    {
        bool participated = false;

        // Binary search could be used instead
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == participant) participated = true;
        }

        return participated;
    }
}
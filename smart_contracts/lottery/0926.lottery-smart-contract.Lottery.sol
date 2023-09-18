// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBaseV2 , Ownable {
    VRFCoordinatorV2Interface COORDINATOR;


    //Same situation as for the owner variable
    address[] public players;

    uint256 public ticketPrice;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        ticketPrice = .001 ether;
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords (
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    //This function receives ether so it is of type payable
    function enter() public payable {
        require(
            msg.value >= ticketPrice,
            "You have to send a Ether minimum"
        );
        players.push(msg.sender);
    }

    //The index variable will always be between 0 and players.length
    function pickWinner() public onlyOwner {
        requestRandomWords();
        uint256 index = s_requestId % players.length;
        //Paying one player by transferring the prize pool to his address
        payable(players[index]).transfer(address(this).balance);
        //Reset the list of players
        players = new address[](0);
    }

    //For each class variable declared with the "public" scope, an implicit getter is created.
    //However, for arrays, not all elements can be returned, you have to fill in the index of the element you want.
    //We declare the function as view because it will not modify any data in the contract, just read
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

}

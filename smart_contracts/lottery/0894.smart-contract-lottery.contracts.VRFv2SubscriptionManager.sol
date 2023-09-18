// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Lotto.sol";

// address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
// address linkTokenContract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
// bytes32 immutable keyHash =
//     0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

contract VRFv2SubscriptionManager is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface immutable i_coordinator;
    LinkTokenInterface immutable i_linkToken;
    Lotto immutable i_lotto;

    bytes32 immutable i_keyHash;
    // uint32 immutable callbackGasLimit = 500_000;
    uint16 immutable requestConfirmations = 3;
    uint32 immutable numWords = 1;

    // Storage parameters
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint64 public s_subscriptionId;
    address immutable i_owner;

    constructor(
        address lotto,
        address linkToken,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_owner = msg.sender;
        i_lotto = Lotto(lotto);
        i_linkToken = LinkTokenInterface(linkToken);
        i_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
    }

    // Create a new subscription when the contract.
    function createNewSubscription() external onlyOwner {
        s_subscriptionId = i_coordinator.createSubscription();
        // Add this contract as a consumer of its own subscription.
        i_coordinator.addConsumer(s_subscriptionId, address(this));
        // i_linkToken.transferAndCall(
        //     address(i_coordinator),
        //     5_000_000_000_000_000_000,
        //     abi.encode(s_subscriptionId)
        // );
    }

    function cancelSubscription() external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        s_subscriptionId = 0;
        i_coordinator.cancelSubscription(s_subscriptionId, msg.sender);
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 callbackGasLimit) external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = i_coordinator.requestRandomWords(
            i_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        i_lotto._receiveWinningNumber(s_randomWords[0]);
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }
}

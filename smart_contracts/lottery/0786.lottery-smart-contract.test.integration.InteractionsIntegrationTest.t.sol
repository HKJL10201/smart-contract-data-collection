// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";

contract InteractionsIntegrationTest is Test {
    uint256 entranceFee = 0.1 ether;
    uint256 interval = 30;
    address public vrfCoordinator;
    Raffle public raffle;
    uint64 public subscriptionId;
    bytes32 gasLane =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 500000;
    address public link;
    uint256 public deployerKey;
    uint256 public constant STARTING_BALANCE = 10 ether;
    address PLAYER = makeAddr("player");

    // Events
    event SubscriptionFunded(
        uint64 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );

    event ConsumerAdded(uint64 indexed subId, address consumer);

    // setup Helperconfig
    function setUp() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            vrfCoordinator,
            subscriptionId,
            ,
            ,
            link,
            deployerKey
        ) = helperConfig.activeNetworkConfig();

        // Deploy Raffle (consumer contract for VRF service)
        hoax(PLAYER, STARTING_BALANCE);

        raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            subscriptionId,
            gasLane,
            callbackGasLimit
        );
    }

    function testCreatingAndFundingSubscriptionFollowedByAddingConsumer()
        public
    {
        vm.recordLogs();
        CreateSubscription createSubscription = new CreateSubscription();
        subscriptionId = createSubscription.createVRFSubscription(
            vrfCoordinator,
            deployerKey
        );

        // Testing funding event emit
        // Step 1: define expectEmit() signature
        vm.expectEmit(
            true,
            true,
            true,
            false,
            address(VRFCoordinatorV2Mock(vrfCoordinator))
        );

        // Step 2: Stimulate the event
        uint256 oldBalance = 0;
        uint96 fundAmt = 3 ether;
        emit SubscriptionFunded(
            subscriptionId,
            oldBalance,
            oldBalance + fundAmt
        );

        // Step 3: Trigger the function that would actually emit the event
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundVRFSubscription(
            vrfCoordinator,
            subscriptionId,
            link,
            deployerKey
        );

        // Testing adding consumer to VRF Subscription event emit
        // Step 1: Define event signature
        vm.expectEmit(
            true,
            true,
            false,
            false,
            address(VRFCoordinatorV2Mock(vrfCoordinator))
        );

        // Step 2: Stimulate the event
        emit ConsumerAdded(subscriptionId, address(raffle));
        // Step 3: Trigger the function that would emit the event
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            address(raffle),
            deployerKey
        );

        assert(subscriptionId > 0);
    }
}

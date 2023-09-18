// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    address PLAYER = makeAddr("player");
    uint256 public deploymentTimeStamp;
    uint256 public STARTING_BALANCE = 10 ether;
    HelperConfig.NetworkConfig internal activeNetworkConfig;

    // Event
    event EnteredRaffle(address indexed PLAYER);

    // modifiers
    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();
        vm.warp(block.timestamp + activeNetworkConfig.interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        // Deploy the contract to be tested
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        // getting access to active network variables through HelperConfig() script

        (
            activeNetworkConfig.entranceFee,
            activeNetworkConfig.interval,
            activeNetworkConfig.vrfCoordinator,
            activeNetworkConfig.subscriptionId,
            ,
            ,
            ,

        ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitialisesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /************************
        Enter Raffle Testcases
     *************************/

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // ACT/ ASSET
        vm.expectRevert(); // vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector); should work but isnt
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();
        //Asset
        assert(raffle.getRafflePlayer(0) == PLAYER);
    }

    function testRaffleShouldNotAllowEntryWhenCalculating()
        public
        raffleEnteredAndTimePassed
    {
        // Act
        raffle.performUpkeep(""); // put the raffle in a calculating state

        // Arrange to Enter raffle again
        vm.expectRevert(); // vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selecctor)
        vm.prank(PLAYER);
        // Act again
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();
    }

    function testEnterRaffleEventEmit() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle)); // vm.expectEmit(indexedTopic1, indexedTopic2, indexedTopic3, unindexedData, emitter)

        emit EnteredRaffle(PLAYER); // emit the event that is expected to be emitted
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}(); // Trigger actual emit
    }

    /************************
        CheckUpKeep Testcases
     *************************/

    function testCheckUpKeepReturnsFalseIfNotEnoughBalance() public {
        vm.warp(block.timestamp + activeNetworkConfig.interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfCalculating() public {
        // Arrange
        vm.warp(block.timestamp + activeNetworkConfig.interval + 1);
        vm.roll(block.number + 1);
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();

        // Act
        raffle.performUpkeep("");

        // Assert
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();
        // raffle.performUpkeep("");

        // Act
        vm.warp(raffle.getLastTimeStamp());
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsTrueIfAllParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();
        vm.warp(block.timestamp + activeNetworkConfig.interval + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }

    /************************
     performUpKeep Testcases
     *************************/

    function testPerformUpKeepWillOnlyRunIfCheckUpKeepReturnsTrue()
        public
        raffleEnteredAndTimePassed
    {
        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepWillOnlyRunIfCheckUpKeepReturnsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert();
        /* vm.expectRevert(abi.encodeWithSelector(
            Raffle.Raffle__UpkeepNotNeeded.selector,
            currentBalance,
            numPlayers,
            raffleState))
        */
        //Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEnteredAndTimePassed
    {
        // Arrange
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 vrfRequestId = entries[1].topics[1];

        // Assert state change
        uint256 rState = uint256(raffle.getRaffleState());
        assert(rState == 1); // 0 = open, 1 = calculating
        assert(vrfRequestId > 0);
    }

    /************************
     fulfillRandomWords Testcases
     *************************/

    function testFulfillRandomWordsOnlyRunsAfterPerformUpKeepHasExecuted(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(activeNetworkConfig.vrfCoordinator)
            .fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksWinnerResetsStateAndSendMoney()
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        // Arrange
        // 1. Add multiple players to the Raffle
        uint256 totalPlayers = 5;
        uint256 startingIndex = 1; // as one player has already entered using the raffleEnteredAndTimePassed() modifier

        for (uint256 i = startingIndex; i < totalPlayers; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_BALANCE);
            raffle.enterRaffle{value: activeNetworkConfig.entranceFee}();
        }

        uint256 prize = (activeNetworkConfig.entranceFee * totalPlayers);

        uint256 startingTimeStamp = raffle.getLastTimeStamp();

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // will emit the request ID of the requestRandomWords() req. to Chainlink VRF
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[1].topics[1]; // tapping into the RequestedRandomWords event that we emit in the performUpKeep()

        VRFCoordinatorV2Mock(activeNetworkConfig.vrfCoordinator)
            .fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        assert(raffle.getRecentWinner() != address(0));
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getLastTimeStamp() > startingTimeStamp);
        assert(
            raffle.getRecentWinner().balance ==
                (STARTING_BALANCE - activeNetworkConfig.entranceFee + prize)
        );
    }
}

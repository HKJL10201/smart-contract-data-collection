// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    Raffle raffle;
    HelperConfig helperConfig;

    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;
    address link;

    uint256 private constant ENTRANCE_FEE = 0.1 ether;

    address public PLAYER = makeAddr("player");
    uint256 constant STARTING_BALANCE = 100 ether; // 1e17

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            raffleEntranceFee,
            callbackGasLimit,
            vrfCoordinatorV2,
            link,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    //////////////////
    // EnterRaffle //
    /////////////////

    function testRaffleEnterRevertsIfYouPayNotEnough() public {
        vm.prank(PLAYER);
        // act / assert
        vm.expectRevert(Raffle.Raffle__LowEntraceFee.selector);
        raffle.enterRaffle();
    }

    function testRaffleInitializesInOpenState() public view {
        // Raffle.RaffleState.OPEN -> pick the RaffleState.OPEN from Raffle contract since it is a enum type
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        address playerAddress = raffle.getPlayer(0);
        assertEq(playerAddress, PLAYER);
    }

    function testRaffleEmitsEventsOnRaffleEnter() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    function testRaffleRevertsOnCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        // passes the time interval
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        // block confirmations
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleStateNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
    }

    ///////////////////
    /// checkUpkeep ///
    ///////////////////

    function testCheckUpReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        // Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upKeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + automationUpdateInterval - 10);

        // Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        assert(upKeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + automationUpdateInterval + 1);

        // Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        assert(upKeepNeeded);
    }

    /////////////////////
    /// performUpkeep ///
    /////////////////////

    modifier RaffleEnterAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE_FEE}();
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        _;
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        RaffleEnterAndTimePassed
    {
        // Act / Assert
        // It doesnt revert
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 balance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpKeepNotNeeded.selector,
                balance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        RaffleEnterAndTimePassed
    {
        vm.recordLogs(); // -> stores the events into the data structure that can bes access with getRecordedLogs
        raffle.performUpkeep(""); // emits the requestId
        // Vm.Log is a special type comes with a foundry test
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // all logs are recorde in bytes32 in foundry
        // entries[0] would be the event emitted by the VRFCoordinatorV2Mock, and entries[1] would be our event RequestedRaffleWinner
        // topics[0] would be the entire event, and topics[1] would be the our requestId
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /////////////////////////
    // fulfillRandomWords //
    ////////////////////////

    modifier skipTest() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    /**
     * VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords is different on mock and actual testnet
     * this event takes two different parameters on mock and actual testnet
     * this only runs on local test not on testnet or mainnet
     */
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public RaffleEnterAndTimePassed skipTest {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        RaffleEnterAndTimePassed
        skipTest
    {
        uint256 additionalPlayers = 5;
        uint256 startingIndex = 1; // since one player is already in
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalPlayers;
            i++
        ) {
            address player = address(uint160(i)); // address(i)
            hoax(player, STARTING_BALANCE); // equivalent to vm.prank and vm.deal function
            raffle.enterRaffle{value: ENTRANCE_FEE}();
        }

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousLastTimestamp = raffle.getLastTimeStamp();
        uint256 prize = ENTRANCE_FEE * (additionalPlayers + 1);

        // we pretend to be a chainlink nodes to kick of the fulfillRandomWords function
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // assert
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getAllPlayers() == 0);
        assert(previousLastTimestamp < raffle.getLastTimeStamp());
        // vm.expectEmit(true, false, false, false, address(raffle));
        // emit PickedWinner(raffle.getRecentWinner());
        console.log(raffle.getRecentWinner().balance);
        console.log((ENTRANCE_FEE * prize - ENTRANCE_FEE));
        assert(
            raffle.getRecentWinner().balance ==
                (STARTING_BALANCE + prize) - ENTRANCE_FEE
        );
    }
}

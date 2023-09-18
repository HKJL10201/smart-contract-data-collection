// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle, HelperConfig} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /*Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;


    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (entranceFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit, link,) =
            helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /////////////////////////////
    // enterRaffle Tests      //
    ///////////////////////////

    function testRaffleRevertsWhenNotEthoughEthSent() public {
        // Arrange
        vm.prank(PLAYER);
        //Act / Assert
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);

        assert(playerRecorded == PLAYER);
    }

    function testRaffleEmitsEnteredRaffleEventOnEntrance() public {
        vm.prank(PLAYER);
        // pass in boolean values for 3 indexed parameters
        // followed by 1 boolean value all undexed paramaters
        // followed by the address of the contract that emitted the event
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    modifier timePassed() {
        // set the block timestamp
        vm.warp(block.timestamp + interval + 1);
        // set the block number
        vm.roll(block.number + 1);
        _;
    }

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }

    modifier skipFork() {
        if(block.chainid != 31337) {
            return;
        }
        _;
    }

    function testCantEnterWhenRaffleIsCalculating() public enteredRaffle timePassed {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testUpkeepReturnsFalseIfIthasNoBalance() public timePassed {
        (bool upkeep,) = raffle.checkUpkeep("");
        assert(!upkeep);
    }

    function testUpkeepReturnsFalseIfRaffleNotOpen() public enteredRaffle timePassed {
        raffle.performUpkeep("");

        (bool upkeep,) = raffle.checkUpkeep("");
        assert(!upkeep);
    }

    function testUpkeepReturnsFalseIfEnoughTimeHasntPassed() public enteredRaffle {
        (bool upkeep,) = raffle.checkUpkeep("");
        assert(!upkeep);
    }

    function testUpkeepReturnsTrueWhenParametersAreGood() public enteredRaffle timePassed {
        (bool upkeep,) = raffle.checkUpkeep("");
        assert(upkeep);
    }

    /**
     * Perform Upkeep Tests
     */

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public enteredRaffle timePassed {
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 playersCount = 0;
        uint256 raffleState = 0;

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, currentBalance, playersCount, raffleState)
        );
        raffle.performUpkeep("");
    }

    function testPeformUpkeepUpdatesRaffleStateAndEmitsRequestId() public enteredRaffle timePassed {
        //Act
        // Record all logs emitted by the next line
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        //all logs from chainlink functions are recorded
        bytes32 requestId = entries[0].topics[2];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /**
     * fullfillRandomWords Tests
     */

    // Fuzz test with random numbers
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
        public
        enteredRaffle
        timePassed
        skipFork
    {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFullfillRandomWordsPicksWinnerResetsAndSendsMoney() public enteredRaffle timePassed skipFork {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for (uint256 i = startingIndex; i <= additionalEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 prize = entranceFee * (additionalEntrants + 1);
        uint256 previousTimestamp = raffle.getLastTimestamp();

        // Record all logs emitted by the next line
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        //all logs from chainlink functions are recorded
        bytes32 requestId = entries[0].topics[2];

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //Assert
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(previousTimestamp < raffle.getLastTimestamp());
        assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE + prize - entranceFee);
    }
}

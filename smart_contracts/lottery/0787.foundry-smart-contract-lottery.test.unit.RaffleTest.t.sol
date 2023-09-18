//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /* Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address coordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant VALUE = 0.1 ether;
    
    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        ( entranceFee,
        interval,
         coordinator,
        keyHash,
        subscriptionId,
        callbackGasLimit,
        link,
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, VALUE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.State.Open);
    }

    /**
     * @dev Enter Raffle Test
     */

    function testRaffleReversesWhenYouDoNotPayEnough() public {
        //arrange
        vm.prank(PLAYER); //pretending to be player
        //act / assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthToEnterRaffle.selector);
        raffle.enterRaffle();
        //assert
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        //arrange
        vm.prank(PLAYER); //pretending to be player
        //act 
        raffle.enterRaffle{value: 10 ether}();
        //assert
        assert(raffle.getNumberOfPlayers() == 1);
    }

    function testRaffleRecordsPlayerIsPlayerWhenTheyEnter() public {
        //arrange
        vm.prank(PLAYER);
         //pretending to be player
        //act
        raffle.enterRaffle{value: 10 ether}();
        address playerRecorded = raffle.getSpecificPlayer(0);
        //assert
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        //arrange
        vm.prank(PLAYER); //pretending to be player
        vm.expectEmit(true, false, false,false, address(raffle));
        emit EnteredRaffle(PLAYER);
        //act 
        raffle.enterRaffle{value: 10 ether}();
        //assert
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        //arrange
        vm.prank(PLAYER); //pretending to be player
        //act
        raffle.enterRaffle{value: 10 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
        //assert 
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER); //pretending to be player
        raffle.enterRaffle{value: 1 ether}();
    }


    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        //assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsTrueIfRaffleNotOpen() public {
        //arrnage
        vm.prank(PLAYER); //pretending to be player     
        raffle.enterRaffle{value: 1 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 
        raffle.performUpKeep("");   

        //act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        //assert
        assert(upKeepNeeded == false);
    }

    //function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() public {}

    //function testCheckUpKeepTrueWhenParametersAreMet() public {}

    //perform upkeep
    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        //arrange
        vm.prank(PLAYER); //pretending to be player
        raffle.enterRaffle{value: 1 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //act/assert 
        raffle.performUpKeep("");  
    }

    function testPerfromUpKeepRevertsIfCheckUpKeepIsFalse() public {
        vm.expectRevert(Raffle.Raffle__NotEnoughTimePassed.selector);
        raffle.enterRaffle{value: 1 ether}();
    }

    //what if I need to test using the output of an event

    modifier raffleEnteredAndTimePassed {
        vm.prank(PLAYER); //pretending to be player
        raffle.enterRaffle{value: 1 ether}();
        vm.warp(block.timestamp + interval + 1);
        _;
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId() public 
    raffleEnteredAndTimePassed {
        //arrange

        //act
        vm.recordLogs(); //gets log outputs 
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        //get the log
        bytes32 requestId = entries[1].topics[1];
        Raffle.State raffleState = raffle.getRaffleState();

        //assert
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    //fufill random words test

    modifier skipFork {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
    function testFufillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId) public raffleEnteredAndTimePassed skipFork{
        //arrange
        vm.expectRevert("nonexistent request");
            VRFCoordinatorV2Mock(coordinator).fulfillRandomWords(
            randomRequestId, 
            address(raffle));
        //act
        
        //assert
    }

    function testFulfillRandomWordsPicksAWinnerResestsAndSendsMoney() raffleEnteredAndTimePassed skipFork public {
        //arrange
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for(uint256 i; i < (startingIndex + additionalEntrants); i++) {
            address player = address(uint160(i)); //generates an address based off i
            hoax(player, VALUE);
            raffle.enterRaffle{value: entranceFee}(); 
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);
        //pretend to be chainlink VRF to get the random word
        vm.recordLogs(); //gets log outputs 
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        //get the log
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimestamp();

        VRFCoordinatorV2Mock(coordinator).fulfillRandomWords(
        uint256 (requestId), 
        address(raffle));
        //act
        //assert
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayersArray() == 0);
        assert(raffle.getLastTimestamp() > previousTimeStamp);
        assert(raffle.getRecentWinner().balance == VALUE + prize - entranceFee);

    }

}

 




    
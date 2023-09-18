// SPDX-License-Identifier: MIT

// Contract Objectives:
// Tests all functionality for the contract: Lottery.sol

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    Lottery lottery;
    HelperConfig helperConfig;

    uint256 entryFee;
    address vrfCoordinatorV2;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    /** Events */
    event NumOfLotteryRounds(uint256 indexed rounds);
    event EnteredLottery(address indexed player);
    event WinnerSelected(address indexed player, uint256 indexed amountWon);
    event RequestedLotteryWinner(uint256 indexed requestId);

    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");
    address USER4 = makeAddr("user4");
    uint256 private constant STARTING_BALANCE = 5 ether;
    uint256 private constant SEND_VALUE = .25 ether;

    function setUp() external {
        DeployLottery deployLottery = new DeployLottery();
        (lottery, helperConfig) = deployLottery.run();
        (
            entryFee,
            vrfCoordinatorV2,
            gasLane,
            subscriptionId,
            callbackGasLimit
        ) = helperConfig.activeNetworkConfig();

        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER3, STARTING_BALANCE);
        vm.deal(USER4, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        lottery.enterLottery{value: SEND_VALUE}();
        _;
    }

    // TESTING enterLottery()
    function testLotteryState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function testOwnerCantEnterLottery() public {
        address owner = msg.sender;
        vm.prank(owner);
        vm.expectRevert();
        lottery.enterLottery{value: SEND_VALUE}();
    }

    function testUserCanOnlyEnterOncePerAddress() public {
        vm.prank(USER);
        lottery.enterLottery{value: SEND_VALUE}();
        vm.expectRevert();
        vm.prank(USER);
        lottery.enterLottery{value: SEND_VALUE}();
        vm.prank(USER2);
        lottery.enterLottery{value: SEND_VALUE}();
        vm.expectRevert();
        vm.prank(USER);
        lottery.enterLottery{value: SEND_VALUE}();
    }

    function testMinimumDeposit() public {
        vm.prank(USER2);
        vm.expectRevert();
        lottery.enterLottery{value: 0.001 ether}();
    }

    function testIfDataStrutureUpdates() public funded {
        uint256 playerEntryDeposit = lottery.getPlayersEntryDeposit(USER);
        assertEq(playerEntryDeposit, SEND_VALUE);
    }

    function testIfPlayerWasAddedToPayablePlayersList() public funded {
        address payable[] memory players = lottery.getListOfPlayers();
        assertEq(players[0], USER);
    }

    function testEventEnteredLotteryEmits() public {
        vm.prank(USER);
        vm.expectEmit(true, false, false, false, address(lottery));
        emit EnteredLottery(USER);
        lottery.enterLottery{value: SEND_VALUE}();
    }

    // TESTING chooseWinner()
    function testBeforeChoosingAWinnerThereMustBeAtLeastOnePlayer() public {
        vm.expectRevert();
        lottery.chooseWinner();
    }
}

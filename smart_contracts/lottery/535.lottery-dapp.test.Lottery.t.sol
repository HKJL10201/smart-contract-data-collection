// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Admin.sol";
import "../src/Lottery.sol";
import "../src/Players.sol";
import "../src/Token.sol";
import "forge-std/console.sol";

contract User {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    receive() external payable {}
}

contract LotteryTestHelper is Test {
    Admin internal admin;
    Lottery internal lottery;
    Players internal players;
    Token internal token;

    User internal userAdmin;
    User internal alice;
    User internal bob;
    User internal charly;

    event Winner(string name, address indexed player, uint256 amount);

    function minimumEnvironment() internal {
        userAdmin = new User("Admin");
        alice = new User("Alice");
        bob = new User("Bob");
        charly = new User("Charly");

        vm.deal(address(userAdmin), 10 ether);
        vm.deal(address(alice), 10 ether);
        vm.deal(address(bob), 10 ether);
        vm.deal(address(charly), 10 ether);

        vm.startPrank(address(userAdmin));
        admin = new Admin();
        token = new Token(1_000_000);
        lottery = new Lottery(address(admin), address(token));
        players = lottery.players();
        vm.stopPrank();
    }

    // Helper functions

    function openPlayers() internal {
        vm.prank(address(userAdmin));
        players.open();
    }

    function closePlayers() internal {
        vm.prank(address(userAdmin));
        players.close();
    }

    function play(User user) internal {
        string memory name = user.name();
        vm.prank(address(user));
        players.play{value: 1 ether}(name);
    }

    function startLottery() internal {
        vm.prank(address(userAdmin));
        lottery.start();
    }

    function finishLottery() internal {
        vm.prank(address(userAdmin));
        lottery.finish();
    }

    function emptyPlayers() internal {
        vm.prank(address(userAdmin));
        players.reset();
    }

    function withdrawEarnings() internal {
        vm.prank(address(userAdmin));
        players.withdraw();
    }

    function fundLottery(uint256 amount) internal {
        vm.prank(address(userAdmin));
        token.transfer(address(lottery), amount);
    }
}

contract TestLottery is Test, LotteryTestHelper {
    function setUp() public {
        minimumEnvironment();
    }

    /*
        Steps to run the game:
        1. Empty players -> admin on Players
        2. Close players -> admin on Players
        3. Start lottery -> admin on Lottery
        4. Fill players -> each player on Players
        5. Close players -> admin on Players
        6. End lottery -> admin on Lottery
        7. Empty players -> admin on Players
    */

    // Actual tests

    function testPlayersAdmin() public {
        assertEq(address(players.admin()), address(admin));
    }

    function testAdminOwner() public {
        assertEq(players.admin().owner(), address(userAdmin));
    }

    function testCannotStartIfPlayersIsOpen() public {
        openPlayers();

        vm.expectRevert("Close new players before starting a new run.");
        startLottery();
    }

    function testCannotStartUntilPlayersAreEmpty() public {
        openPlayers();
        play(alice);
        closePlayers();

        vm.expectRevert("Start a new run with zero players.");
        startLottery();
    }

    function testStartLottery() public {
        startLottery();

        assertEq(lottery.running(), true);
    }

    function testCannotFinishIfLotteryIsNotRunning() public {
        vm.expectRevert("Lottery must be running.");
        finishLottery();
    }

    function testCannotFinishIfPlayersIsOpen() public {
        startLottery();

        openPlayers();

        vm.expectRevert("Close players before continuing.");
        finishLottery();
    }

    function testCannotFinishIfNotEnoughPlayers() public {
        startLottery();

        openPlayers();
        play(alice);
        closePlayers();

        vm.expectRevert("Not enough players.");
        finishLottery();
    }

    function testCannotFinishIfNotEnoughBalance() public {
        startLottery();

        openPlayers();
        play(alice);
        play(bob);
        closePlayers();

        vm.expectRevert("Not enough tokens for the prize.");
        finishLottery();
    }

    function testLotteryNotRunningAfterFinished() public {
        startLottery();

        openPlayers();
        play(alice);
        play(bob);
        closePlayers();

        fundLottery(2);

        finishLottery();

        assertEq(lottery.running(), false);
    }

    function testEmitWinnerEvent() public {
        startLottery();

        openPlayers();
        play(alice);
        play(bob);
        closePlayers();

        fundLottery(2);

        vm.expectEmit(true, true, true, true, address(lottery));
        emit Winner(alice.name(), address(alice), 2);

        finishLottery();
    }

    // @note The following test involves changing the blockhash or block.number
    // function testDifferentWinner() public {
    //     // Change blockhash or block.number
    //     startLottery();

    //     openPlayers();
    //     play(alice);
    //     play(bob);
    //     closePlayers();

    //     fundLottery(2);

    //     vm.expectEmit(true, true, true, true, address(lottery));
    //     emit Winner(bob.name(), address(bob), 2);
    //     finishLottery();
    // }

    function testFundsTransmitted() public {
        startLottery();

        openPlayers();
        play(alice);
        play(bob);
        play(charly);
        closePlayers();

        fundLottery(3);
        finishLottery();

        assertEq(token.balanceOf(address(alice)), 3);
    }
}

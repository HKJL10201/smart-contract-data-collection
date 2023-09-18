// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Players.sol";
import "../src/Admin.sol";

contract User {}

contract Game is Runnable {
    bool public running;

    function setRunning(bool _running) public {
        running = _running;
    }
}

contract TestPlayers is Test {
    Game game;
    Admin admin;
    Players players;
    User alice;
    User bob;

    event NewPlayer(address indexed newPlayer, uint256 number);

    receive() external payable {}

    function setUp() public {
        admin = new Admin();
        game = new Game();

        alice = new User();
        bob = new User();

        vm.deal(address(alice), 5 ether);
        vm.deal(address(bob), 5 ether);

        players = new Players(address(admin), address(game));
    }

    function testAdmin() public {
        assertEq(address(players.admin()), address(admin));
        assertEq(players.admin().owner(), address(this));
    }

    function testInit() public {
        assertEq(players.isMember(address(alice)), false);
        assertEq(players.isMember(address(bob)), false);

        string memory name1;
        address address1;

        (name1, address1) = players.members(0);
        assertEq(name1, "");
        assertEq(address1, address(0));

        string memory name2;
        address address2;

        (name2, address2) = players.members(0);
        assertEq(name2, "");
        assertEq(address2, address(0));

        assertEq(players.membersCount(), 0);
    }

    function testStart() public {
        assertEq(players.isOpen(), false);
        players.open();
        assertEq(players.isOpen(), true);
    }

    function testStop() public {
        players.open();
        assertEq(players.isOpen(), true);
        players.close();
        assertEq(players.isOpen(), false);
    }

    function testIsNotOpen() public {
        vm.expectRevert("New players not accepted.");

        players.play{value: 1 ether}("Console");
    }

    function testPlay() public {
        players.open();

        vm.prank(address(alice));
        players.play{value: 1 ether}("Alice");

        (string memory name, address address1) = players.members(0);

        assertEq(name, "Alice");
        assertEq(address1, address(alice));
        assertEq(players.isMember(address(alice)), true);
        assertEq(players.membersCount(), 1);
    }

    function testPlayEvent() public {
        players.open();

        vm.expectEmit(true, true, true, true, address(players));
        emit NewPlayer(address(alice), 0);

        vm.prank(address(alice));
        players.play{value: 1 ether}("Alice");
    }

    function testPlayTwo() public {
        players.open();

        vm.prank(address(alice));
        players.play{value: 1 ether}("Alice");

        (string memory aName, address aAddress) = players.members(0);
        assertEq(aName, "Alice");
        assertEq(aAddress, address(alice));
        assertEq(players.isMember(address(alice)), true);
        assertEq(players.membersCount(), 1);

        vm.prank(address(bob));
        players.play{value: 1 ether}("Bob");

        (string memory bName, address bAddress) = players.members(1);
        assertEq(bName, "Bob");
        assertEq(bAddress, address(bob));
        assertEq(players.isMember(address(bob)), true);
        assertEq(players.membersCount(), 2);
    }

    function testNotEnough() public {
        assertEq(players.enough(), false);
    }

    function testEnough() public {
        players.open();

        uint256 minimum = 2;

        for (uint160 count = 0; count < minimum; count++) {
            address newAddress = address(count + 0xffffffff);
            vm.deal(newAddress, 1 ether);
            vm.prank(newAddress);
            players.play{value: 1 ether}("Some player");
        }

        assertEq(players.enough(), true);
    }

    function testPlayTwice() public {
        players.open();

        players.play{value: 1 ether}("Console");

        vm.expectRevert("Player is already a member.");
        players.play{value: 1 ether}("Console");
    }

    function testWithdraw() public {
        players.open();

        uint256 startBalance = address(this).balance;
        players.play{value: 1 ether}("Console");
        assertEq(address(this).balance, startBalance - 1 ether);

        vm.prank(address(alice));
        players.play{value: 1 ether}("Alice");

        players.withdraw();

        assertEq(address(this).balance, startBalance + 1 ether);
    }

    function testWithdrawUnauthorized() public {
        players.open();

        players.play{value: 1 ether}("Console");

        vm.prank(address(alice));
        vm.expectRevert("Not the admin.");
        players.withdraw();
    }

    function testCannotResetIfGameIsRunning() public {
        players.open();

        vm.prank(address(alice));
        players.play{value: 1 ether}("Alice");
        vm.prank(address(bob));
        players.play{value: 1 ether}("Bob");

        game.setRunning(true);

        vm.expectRevert("Lottery must not be running.");
        players.reset();
    }

    function testReset() public {
        players.open();

        vm.prank(address(alice));
        players.play{value: 1 ether}("Alice");
        vm.prank(address(bob));
        players.play{value: 1 ether}("Bob");

        game.setRunning(false);

        players.reset();

        assertEq(players.membersCount(), 0);

        (string memory name, address player) = players.members(0);
        assertEq(name, "");
        assertEq(player, address(0));

        (name, player) = players.members(1);
        assertEq(name, "");
        assertEq(player, address(0));

        assertEq(players.isMember(address(alice)), false);
        assertEq(players.isMember(address(bob)), false);
    }
}

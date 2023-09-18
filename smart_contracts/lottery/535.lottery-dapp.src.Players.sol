// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Admin.sol";

struct Player {
    string name;
    address _address;
}

interface Runnable {
    function running() external view returns (bool);
}

interface IPlayers {
    function play(string memory name) external payable;
    function open() external;
    function close() external;
    function enough() external view returns (bool);
    function withdraw() external;
    function reset() external;
}

contract Players is IPlayers {
    mapping(uint256 => Player) public members;
    mapping(address => bool) public isMember;
    uint256 public membersCount;

    bool public isOpen;
    bool private lock;

    Admin public admin;
    Runnable public lottery;

    event NewPlayer(address indexed newPlayer, uint256 number);

    constructor(address _admin, address _lottery) {
        admin = Admin(_admin);
        lottery = Runnable(_lottery);
    }

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == admin.owner(), "Not the admin.");
        _;
    }

    modifier noReentrancy() {
        require(!lock, "No reentrancy");
        lock = true;
        _;
        lock = false;
    }

    modifier lotteryStopped() {
        require(!lottery.running(), "Lottery must not be running.");
        _;
    }

    // Public API

    function play(string memory name) external payable {
        require(isOpen, "New players not accepted.");
        require(!isMember[msg.sender], "Player is already a member.");
        require(msg.sender != address(0), "Cannot use address 0");
        require(msg.value == 1 ether, "Ticket price is 1 ether.");

        emit NewPlayer(msg.sender, membersCount);

        members[membersCount] = Player(name, msg.sender);
        isMember[msg.sender] = true;
        membersCount++;
    }

    function enough() public view returns (bool) {
        return membersCount >= 2;
    }

    // Admin API

    function open() external onlyAdmin {
        isOpen = true;
    }

    function close() external onlyAdmin {
        isOpen = false;
    }

    function withdraw() external onlyAdmin noReentrancy {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Error withdrawing ETH");
    }

    function reset() external onlyAdmin lotteryStopped {
        for (uint256 index = 0; index < membersCount; index++) {
            Player memory player = members[index];
            members[index] = Player("", address(0));
            isMember[player._address] = false;
        }
        membersCount = 0;
    }
}

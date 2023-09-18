// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Players.sol";
import "./Admin.sol";
import "./Token.sol";

interface ILottery {
    function start() external;
    function finish() external;
}

contract Lottery is ILottery {
    Players public players;
    Admin public admin;
    Token public token;

    bool public running;

    event Winner(string name, address indexed player, uint256 amount);

    constructor(address _admin, address _token) {
        admin = Admin(_admin);

        players = new Players(_admin, address(this));
        token = Token(_token);
    }

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == admin.owner(), "Not the admin.");
        _;
    }

    // Admin API

    function start() external onlyAdmin {
        require(!players.isOpen(), "Close new players before starting a new run.");
        require(players.membersCount() == 0, "Start a new run with zero players.");

        running = true;
    }

    function finish() external onlyAdmin {
        require(running, "Lottery must be running.");
        require(!players.isOpen(), "Close players before continuing.");
        require(players.enough(), "Not enough players.");
        require(token.balanceOf(address(this)) >= players.membersCount(), "Not enough tokens for the prize.");

        uint256 random = uint256(blockhash(block.number - 1));
        require(random != 0, "Random number cannot be 0");
        uint256 stepSize = type(uint256).max / players.membersCount();
        uint256 winnerNumber = random / stepSize;

        string memory winnerName;
        address winnerAddress;
        (winnerName, winnerAddress) = players.members(winnerNumber);
        require(winnerAddress != address(0), "Address 0 cannot be a winner!");

        uint256 amount = players.membersCount();
        emit Winner(winnerName, winnerAddress, amount);

        token.transfer(winnerAddress, amount);
        running = false;
    }
}

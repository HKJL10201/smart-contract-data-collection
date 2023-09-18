/**
 *Submitted for verification at Etherscan.io on 2022-11-04
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19 .0;

import {IJoKenPo} from "./IJoKenPo.sol";
import {JKPLibrary} from "./JKPLibrary.sol";

contract JoKenPo is IJoKenPo {
    JKPLibrary.Options private choice1 = JKPLibrary.Options.NONE;
    address private player1;
    string private result = "";
    uint256 private bid = 0.01 ether;
    uint8 private commission = 10; // percent

    address payable private immutable owner;

    JKPLibrary.Winner[] public winners;

    constructor() {
        owner = payable(msg.sender);
    }

    function getResult() external view returns (string memory) {
        return result;
    }

    function getBid() external view returns (uint256) {
        return bid;
    }

    function getCommission() external view returns (uint8) {
        return commission;
    }

    function setBid(uint256 newBid) external restricted {
        require(player1 == address(0), "Game in progress");
        bid = newBid;
    }

    function setCommission(uint8 newCommission) external restricted {
        require(player1 == address(0), "Game in progress");
        require(
            newCommission >= 0 && newCommission <= 100,
            "Between 0 and 100"
        );
        commission = newCommission;
    }

    function updateWinner(address winner) private {
        for (uint i = 0; i < winners.length; i++) {
            if (winners[i].wallet == winner) {
                winners[i].wins++;
                return;
            }
        }
        winners.push(JKPLibrary.Winner(winner, 1));
    }

    function finishGame(string memory newResult, address winner) private {
        address contractAddress = address(this);
        payable(winner).transfer(
            (contractAddress.balance / 100) * (100 - commission)
        );
        owner.transfer(contractAddress.balance);

        updateWinner(winner);

        result = newResult;
        player1 = address(0);
        choice1 = JKPLibrary.Options.NONE;
    }

    function getBalance() external view restricted returns (uint) {
        return address(this).balance;
    }

    function play(
        JKPLibrary.Options newChoice
    ) external payable returns (string memory) {
        require(tx.origin != owner, "The owner cannot play");
        require(newChoice != JKPLibrary.Options.NONE, "Invalid choice");
        require(player1 != tx.origin, "Wait the another player");
        require(msg.value >= bid, "Invalid bid");

        if (choice1 == JKPLibrary.Options.NONE) {
            player1 = tx.origin;
            choice1 = newChoice;
            result = "Player 1 choose his/her option. Waiting player 2.";
        } else if (
            choice1 == JKPLibrary.Options.ROCK &&
            newChoice == JKPLibrary.Options.SCISSORS
        ) finishGame("Rock breaks scissors. Player 1 won.", player1);
        else if (
            choice1 == JKPLibrary.Options.PAPER &&
            newChoice == JKPLibrary.Options.ROCK
        ) finishGame("Paper wraps rock. Player 1 won.", player1);
        else if (
            choice1 == JKPLibrary.Options.SCISSORS &&
            newChoice == JKPLibrary.Options.PAPER
        ) finishGame("Scissors cuts paper. Player 1 won.", player1);
        else if (
            choice1 == JKPLibrary.Options.SCISSORS &&
            newChoice == JKPLibrary.Options.ROCK
        ) finishGame("Rock breaks scissors. Player 2 won.", tx.origin);
        else if (
            choice1 == JKPLibrary.Options.ROCK &&
            newChoice == JKPLibrary.Options.PAPER
        ) finishGame("Paper wraps rock. Player 2 won.", tx.origin);
        else if (
            choice1 == JKPLibrary.Options.PAPER &&
            newChoice == JKPLibrary.Options.SCISSORS
        ) finishGame("Scissors cuts paper. Player 2 won.", tx.origin);
        else {
            result = "Draw game. The prize was doubled";
            player1 = address(0);
            choice1 = JKPLibrary.Options.NONE;
        }

        return result;
    }

    function getLeaderBoard()
        external
        view
        returns (JKPLibrary.Winner[] memory)
    {
        if (winners.length < 2) return winners;

        JKPLibrary.Winner[] memory arr = new JKPLibrary.Winner[](
            winners.length
        );
        for (uint i = 0; i < winners.length; i++) {
            arr[i] = winners[i];
        }

        for (uint i = 0; i < arr.length - 1; i++) {
            for (uint j = 1; j < arr.length; j++) {
                if (arr[i].wins < arr[j].wins) {
                    JKPLibrary.Winner memory change = arr[i];
                    arr[i] = arr[j];
                    arr[j] = change;
                }
            }
        }
        return arr;
    }

    modifier restricted() {
        require(owner == tx.origin, "You do not have permission");
        _;
    }
}

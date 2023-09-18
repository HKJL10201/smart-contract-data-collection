// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BoxOracle.sol";


contract Betting {

    struct Player {
        uint8 id;
        string name;
        uint totalBetAmount;
        uint currCoef;
    }

    struct Bet {
        address bettor;
        uint amount;
        uint player_id;
        uint betCoef;
    }

    address private betMaker;
    BoxOracle public oracle;
    uint public minBetAmount;
    uint public maxBetAmount;
    uint public totalBetAmount;
    uint public thresholdAmount;

    Bet[] private bets;
    Player public player_1;
    Player public player_2;

    bool private suspended = false;
    mapping(address => uint) public balances;

    constructor(
        address _betMaker,
        string memory _player_1,
        string memory _player_2,
        uint _minBetAmount,
        uint _maxBetAmount,
        uint _thresholdAmount,
        BoxOracle _oracle
    ) {
        betMaker = (_betMaker == address(0) ? msg.sender : _betMaker);
        player_1 = Player(1, _player_1, 0, 200);
        player_2 = Player(2, _player_2, 0, 200);
        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;
        thresholdAmount = _thresholdAmount;
        oracle = _oracle;

        totalBetAmount = 0;
    }

    receive() external payable {}

    fallback() external payable {}

    function makeBet(uint8 _playerId) public payable {
        require(msg.value >= minBetAmount && msg.value <= maxBetAmount);
        require(oracle.getWinner() == 0);
        require(_playerId == 1 || _playerId == 2);
        require(msg.sender != betMaker);

        totalBetAmount += msg.value;

        if (_playerId == player_1.id) {
            player_1.totalBetAmount += msg.value;
        }
        if (_playerId == player_2.id) {
            player_2.totalBetAmount += msg.value;
        }

        if (totalBetAmount >= thresholdAmount) {
            if (player_1.totalBetAmount == 0 || player_2.totalBetAmount == 0) {
                suspended = true;
            } else {
                player_1.currCoef = (totalBetAmount / player_1.totalBetAmount) * (10 ** 2);
                player_2.currCoef = (totalBetAmount / player_2.totalBetAmount) * (10 ** 2);
            }
        }

        bets.push(Bet({
        bettor : msg.sender,
        amount : msg.value,
        player_id : _playerId,
        betCoef : _playerId == player_1.id ? player_1.currCoef : player_2.currCoef
        }));
    }

    function claimSuspendedBets() public {
        require(suspended);

        for (uint i = 0; i < bets.length; i++) {
            Bet storage bet = bets[i];
            if (msg.sender == bet.bettor) {
                payable(bet.bettor).transfer(bet.amount);
            }
        }
    }

    function claimWinningBets() public {
        require(oracle.getWinner() != 0 && !suspended);

        for (uint i = 0; i < bets.length; i++) {
            Bet storage bet = bets[i];
            if (msg.sender == bet.bettor && bet.player_id == oracle.getWinner()) {
                uint winnings = bet.amount * (bet.betCoef / 100);
                payable(bet.bettor).transfer(winnings);
                delete bets[i];
            }
        }
    }

    function claimLosingBets() public {
        require(msg.sender == betMaker);
        require(oracle.getWinner() != 0);
        uint totalToPay = 0;

        for (uint i = 0; i < bets.length; i++) {
            Bet storage bet = bets[i];
            if (bet.player_id != oracle.getWinner()) {
                totalToPay += bet.amount;
            } else {
                revert();
            }
        }

        payable(betMaker).transfer(totalToPay);
    }

}
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

contract Tontine {
    uint256 public dues;
    uint256 public interval;
    uint256 public minPlayers;
    address[] public players;
    bool public allowLatecomers;
    bool public heirMustLive;

    mapping(address => uint256) public latestPayments;

    enum State {
        Awaiting,
        Ongoing,
        Ended
    }

    State public state = State.Awaiting;

    event Contribution(address indexed player, uint256 time);
    event StateChange(State state, uint256 time);

    constructor(
        uint256 _dues,
        uint256 _interval,
        uint256 _minPlayers,
        bool _allowLatecomers,
        bool _heirMustLive
    ) {
        require(_minPlayers > 1, "minPlayers must be greater than 1");
        dues = _dues;
        interval = _interval;
        minPlayers = _minPlayers;
        allowLatecomers = _allowLatecomers;
        heirMustLive = _heirMustLive;
    }

    function contribute() public payable {
        require(state != State.Ended, "tontine has ended");
        require(msg.value == dues, "incorrect dues amount sent");

        uint256 latestPayment = latestPayments[msg.sender];

        if (latestPayment == 0) {
            require(
                state == State.Awaiting || allowLatecomers,
                "tontine is in progress and latecomers are not allowed"
            );
            players.push(msg.sender);
        } else {
            require(
                state == State.Ongoing,
                "already initial paid dues, awaiting other players to start"
            );

            require(
                latestPayment < block.timestamp - interval - interval,
                "payment too late, you have been eliminated"
            );

            require(
                latestPayment > block.timestamp - interval,
                "already paid dues this cycle"
            );
        }

        if (players.length == minPlayers) {
            state = State.Ongoing;

            for (uint256 i = 0; i < players.length; i++) {
                latestPayments[players[i]] = block.timestamp;
            }

            emit StateChange(state, block.timestamp);
        } else {
            latestPayments[msg.sender] = block.timestamp;
        }

        if (players.length >= minPlayers) {
            emit Contribution(msg.sender, block.timestamp);
        }
    }

    function claim() public {
        require(state == State.Ongoing, "tontine has not started");
        require(
            latestPayments[msg.sender] != 0,
            "you are not an active player"
        );

        uint256 deadline = block.timestamp - interval - interval;

        require(
            !heirMustLive || latestPayments[msg.sender] > deadline,
            "cannot withdraw, you are dead"
        );

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                continue;
            }

            require(
                latestPayments[players[i]] <= deadline,
                "cannot withdraw, other players survive"
            );
        }

        state = State.Ended;
        emit StateChange(state, block.timestamp);
        selfdestruct(payable(msg.sender));
    }
}

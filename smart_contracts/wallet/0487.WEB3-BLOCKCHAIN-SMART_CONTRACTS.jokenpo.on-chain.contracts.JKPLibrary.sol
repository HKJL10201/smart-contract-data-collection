// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19 .0;

library JKPLibrary {
    enum Options {
        NONE,
        ROCK,
        PAPER,
        SCISSORS
    } //0, 1, 2, 3

    struct Winner {
        address wallet;
        uint32 wins;
    }
}

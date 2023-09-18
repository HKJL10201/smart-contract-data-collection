// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This function is a proxy for oracle and is used in testing.
// Usually, one would call outside oracle via API for getting the winner.
contract BoxOracle {

    uint8 winner;
    address owner;

    constructor (){
        owner = msg.sender;
        winner = 0;
    }

    function getWinner() public view returns (uint8){
        return winner;
    }

    function setWinner(uint8 _player) public ownerOnly {
        winner = _player;
    }
    modifier ownerOnly {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}
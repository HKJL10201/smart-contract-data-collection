// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Voting {

    struct Voter {
        address addr;
        bool isRegistered;
        bool hasVoted;
    }

    address public chairPerson;

    constructor() {
        chairPerson = msg.sender;
    }

    modifier onlyChairPerson {
        require(msg.sender == chairPerson);
        _;
    }
}
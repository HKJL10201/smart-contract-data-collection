// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Voters{ 
    struct Voter{ 
        address voterAddress;
    }
    
    struct VoteRecord{ 
        uint electionId;
        mapping(address => bool) voted;
    }

    //Number of voters;
    uint voterCount;

    //Voting roll of voters;
    mapping (address => Voter) public voterRoll;

    VoteRecord[] voteRecordList;
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ballot{

    //All code goes here

    //struct is a method to create and store your data types

    struct Proposal {
        bytes32 name; //name of each proposal
        uint voteCount; //number of accumulated votes
    }

    //voters: voted = bool, access to vote = uint, vote index = uint
    struct Voter {
        uint vote;
        bool voted;
        uint wheight;
    }
    
    Proposal [] public proposals;

    //mapping allows us to create and store values with keys and indexes
    mapping(address => Voter) public voters; //voters get address as key and Voter for value
}
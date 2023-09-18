// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract ElectionStorage {

    struct Candidate{ 
        uint id;
        address addr; 
        uint voteCount; 
    }

    struct Election{ 
        uint id;
        uint duration;              
        uint amount;                //fee to be paid by the voter
        uint voteFee;               //commission fee to vote
        Candidate[] candidates;     //list of candidates 
        uint electionEnd;           //end time
        uint electionStart;         //start time
    }

	uint public currentElectionId;
   
    //list of all elections
	Election[] elections;

}
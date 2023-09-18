//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//Note: this code is currently in progress.

// @dev import ownable.sol contract to restrict access and provide a layer of protection and design

import "http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";


// @dev import SafeMath.sol contract

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";



contract Ballot {
    using SafeMath for uint256; // @dev add safemath so there are no overflows/underflows
    struct Voter {
        bool approved;
        bool voted;
        address delegate;
    }

    struct Proposal {
        bytes32 id;
        address instructor;
        uint voteCount;
        bool approved;
    }

    address public chairperson;

    mapping(address => Voter)public voters;

    Proposal public proposal;

    constructor(bytes32 proposalName) public {
        chairperson = msg.sender;
        voters[chairperson].approved = true;

        proposal.id = proposalName;
        proposal.voteCount = 0;
        proposal.approved = false;
    }

    function giveRightToVote(address voter)public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote.");
        require(
            !voters[voter].voted,
            "The voter already voted.");

        voters[voter].delegate = voter;
        voters[voter].approved = true;
        require(
            voters[voter].approved != true,
            "Saved at least local");   
    }

    function voteYes()public {
        Voter storage sender = voters[msg.sender];
        require(sender.approved !=false, "Has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;

        proposal.voteCount += 1;
    }

    function determineAcceptance(uint numVoters) public {
        require(
            proposal.voteCount >= numVoters * 2/3,
            "This proposal has not gained enough votes."
            );
        proposal.approved = true;
    }
}

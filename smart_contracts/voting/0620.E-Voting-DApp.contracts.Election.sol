// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {

    // declare candidate model: names, vote counts, ID
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    // store candidates and fetch candidates
    mapping(uint => Candidate) public candidates;

    // store accounts that have voted
    mapping(address => bool) public voters;

    // storing candidate count
    uint public candidateCount;

    // constructor to store and read candidate model
    constructor () public {
        // put candidates here
        addCandidate("Candidate A");
        addCandidate("Candidate B");
    }

    // voting event
    event voteEvent (
        uint indexed _candidateId
    );

    // function to add candidate
    function addCandidate(string memory _name) private{
        candidateCount++ ;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    // function to add votes and voting
    function vote(uint _candidateId) public {

        // requirement that address has't voted before and checking if candidate is valid
        require(!voters[msg.sender]);
        require( _candidateId <= candidateCount && _candidateId > 0);

        // recording that voter has voted + updating count of votes
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit voteEvent(_candidateId);
    }

}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract ElectionManager {
    uint public id = 0;

    event ElectionCreated(uint id, address createdBy, uint registrationEnd, uint votingEnd);
    event CandidateRegistered(uint electionId, address candidate);
    event Vote(uint electionId, address voter, address candidate);

    struct Election{
        mapping(address=>uint) candidateVotes;
        address[] candidates;
        address[] voters;
        uint registrationEnd;
        uint votingEnd;
    }

    struct ReturnedElection{
        address[] candidates;
        uint[] votes;
    }

    mapping(uint => Election) elections;

    function getElection(uint _id) external view returns(ReturnedElection memory){
        Election storage election = elections[_id];
        ReturnedElection memory returnedElection;
        returnedElection.votes = new uint[](election.candidates.length);
        for(uint i=0; i < election.candidates.length; i++){
            returnedElection.votes[i] = (election.candidateVotes[election.candidates[i]]);
        }
        returnedElection.candidates = election.candidates;
        return returnedElection;
    }

    function createElection(uint _registrationPeriodMinutes, uint _votingPeriodMinutes) external {
        //create election with unique id
        id++;
        Election storage newElection = elections[id];
        uint registrationEnd = block.timestamp + (_registrationPeriodMinutes * 1 minutes);
        uint votingEnd = registrationEnd + (_votingPeriodMinutes * 1 minutes);
        newElection.registrationEnd = registrationEnd;
        newElection.votingEnd = votingEnd;
        //emit event
        emit ElectionCreated(id, msg.sender, registrationEnd, votingEnd);
    }

    //register candidate to a specified election
    function registerCandidate(uint _electionId) external {
        Election storage election = elections[_electionId];
        //check registration is still open
        require(block.timestamp < election.registrationEnd, "Registration ended");
        //check if they are already a candidate
        require(!_addressCheck(election.candidates, msg.sender), "candidate already registered");
        //register candidate
        election.candidates.push(msg.sender);
        //emit event
        emit CandidateRegistered(_electionId, msg.sender);

    }

    //vote on a specified election
    function vote(uint _electionId, address _candidate) external {
        Election storage election = elections[_electionId];
        //check voting is open
        require(block.timestamp < election.votingEnd, "Voting has ended");
        //check if candidate exists in election
        require(_addressCheck(election.candidates, _candidate), "No candidate with this address registered in election");
        //check if they have voted already
        require(!_addressCheck(election.voters, msg.sender), "Already voted in this election");
        //add voter to array
        election.voters.push(msg.sender);
        //apply vote
        election.candidateVotes[_candidate]++;
        //emit event
        emit Vote(_electionId, msg.sender, _candidate);

    }

    //checks if address is in array of addresses
    function _addressCheck(address[] memory _addresses, address _address) private pure returns(bool){
        for(uint i=0;i < _addresses.length;i++){
            if(_addresses[i] == _address){
                return true;
            }
        }
        return false;
    }


}


/*
Allow anyone to start an election with a registration period, voting period, 
and ending time. Allow anyone to sign up as a candidate during the registration period, 
and allow anyone to vote once during the voting period. 
*/
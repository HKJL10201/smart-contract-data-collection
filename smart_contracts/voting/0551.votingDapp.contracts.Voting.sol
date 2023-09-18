// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract Voting 
{
  
    struct Candidate 
    {
        bytes32 name;   
        uint voteCount; 
    }
    struct Election 
    {
        address chairperson;                        //creator
        bool ended;                                 
        uint endTime;                               //ending time
    }

   mapping(uint => mapping(address => bool)) voted;
   Candidate[][1e5] public candidates;
   // bytes32[][] public name;
   // uint[][] public votes;


    uint num = 0;           //number of elections
    Election[] public elections;

    function isRunning(uint _electionId) public view returns(bool)
    {
        return (block.timestamp<=elections[_electionId].endTime);
    }

    function getTimeLeft(uint _electionId) external view returns (uint)
    {
        return (uint(elections[_electionId].endTime) - uint(block.timestamp));
    }

    function getNum() external view returns(uint) 
    {
        return num;
    }

    function getNumOfCandidates(uint _electionId) external view returns(uint) {
        return candidates[_electionId].length;
        //return votes[_electionId].length;
    }

    function getCandidate(uint _electionId, uint _candidateId) external view returns(bytes32) {
        return candidates[_electionId][_candidateId].name;
        //return name[_electionId][_candidateId];
    }

    function getVotes(uint _electionId, uint _candidateId) external view returns(uint) {
        return candidates[_electionId][_candidateId].voteCount;
        //return votes[_electionId][_candidateId];
    }

    ////////
    
    function createElection(bytes32[] calldata proposalNames, uint votingTime) external
    {
        /*
        uint _endTime = votingTime+block.timestamp;

        Election storage newElection = elections[num++];


        newElection.chairperson = msg.sender;
        newElection.ended = false;
        newElection.endTime = _endTime;

        for (uint i = 0; i < proposalNames.length; i++) 
        {
                newElection.candidates.push(Candidate({
                name: proposalNames[i],
                voteCount: 0
            }));
        }*/

        elections.push(Election(msg.sender, false, votingTime+block.timestamp));

        for (uint i = 0; i < proposalNames.length; i++) 
        {
                candidates[num].push(Candidate({
                name: proposalNames[i],
                voteCount: 0
            }));
        }

        num++;


    }

    function vote(uint _electionId, uint _id) external
    {

        Election storage ballot = elections[_electionId];
        if(block.timestamp>ballot.endTime)
        {
            revert("voting has ended");
        }

        Candidate storage receiver = candidates[_electionId][_id];
        require(voted[_electionId][msg.sender]==false);
        receiver.voteCount++;
        voted[_electionId][msg.sender] = true;
        

    }

}
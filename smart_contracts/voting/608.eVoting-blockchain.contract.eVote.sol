pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract EVoting {
    uint256 public startVotingTime;
    uint256 public endVotingTime;
    mapping(bytes32 => uint) public voterTimestamps; // stores the timestamp of voting for each voter
    uint public totalVotes;  // stores total no of votes
    mapping(bytes32 => bytes32) public candidateVotes; //mapping is intended to keep track of the votes cast for each candidate,
    address public admin; // admin or chairperson decides voting
    
    constructor()  {
        // admindetails = Admindetails(_adminName );
        admin = msg.sender;
    }
    
    function getAdmin() public view returns (address) {
        return (admin);
    }  
    
    modifier onlyadmin() {
        // Modifier for only admin access
        require(msg.sender == admin);
        _;
    }

    function vote(bytes32 _voteHash, bytes32 _candidateHash) public {
        require( block.timestamp > startVotingTime, "Election has not started yet.");
        require( block.timestamp < endVotingTime, "Election has ended.");
        candidateVotes[_candidateHash] = _voteHash;
        voterTimestamps[_voteHash] = block.timestamp;
        totalVotes++;
    }

    function getCandidateVoteHash(bytes32 _candidateHash) public view returns (bytes32) {
        bool hasVotingEnded = block.timestamp > endVotingTime;
        require(hasVotingEnded || msg.sender == admin, "Vote count not available yet.");

        return candidateVotes[_candidateHash];
    }

    function setVotingTime(uint _startVotingTime, uint _endVotingTime) public onlyadmin {
        require(block.timestamp < _startVotingTime, "Starting time should be in future");
        require((block.timestamp < _endVotingTime) && _endVotingTime > _startVotingTime , "End time for voting  to be greater than start time");
        startVotingTime = _startVotingTime;
        endVotingTime = _endVotingTime;
    }

    function extendVotingTime(uint _newEndTime) public onlyadmin {
        require(block.timestamp < endVotingTime, "Voting already ended");
        endVotingTime = _newEndTime;
    }
}
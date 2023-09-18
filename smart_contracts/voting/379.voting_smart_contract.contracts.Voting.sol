// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    address owner;
    uint lastVoteID;
    uint comission;

    struct Vote {
        bool active;
        uint startDate;
        uint budget;
        address payable winner;
        address[] voters;
        mapping(address => bool) isCandidate;
        mapping(address => bool) voted;
        mapping(address => uint) votesCount;
    }

    mapping(uint => Vote) votes;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly {
        require (
            msg.sender == owner, "Permission denied"
        );
        _;
    }

    function startVoting(address[] memory _candidates) external ownerOnly {
        Vote storage v = votes[lastVoteID++];
        v.active = true;
        v.startDate = block.timestamp;

        // expensive but necessary loop below
        // without it we cant get list of candidates as said on task requirements
        for (uint i = 0; i < _candidates.length; i++) {
            v.isCandidate[_candidates[i]] = true;
        }
    }

    

    function vote(uint _voteID, address payable _to) external payable {
        require(votes[_voteID].active, "Voting is not active");
        require(votes[_voteID].isCandidate[_to], "No such candidate on the vote");
        require(!votes[_voteID].voted[msg.sender], "You already voted");
        require(msg.value == 10000000000000000, "Cost of voting is 0.01 ETH");
        
        votes[_voteID].voters.push(msg.sender);
        votes[_voteID].voted[msg.sender] = true;
        votes[_voteID].votesCount[_to] += 1;

        // Due to condition below, winner is the first who beats last max vote
        if (votes[_voteID].votesCount[_to] > votes[_voteID].votesCount[votes[_voteID].winner]) {
            votes[_voteID].winner = _to; // Register new winner
        }

        // Adding 90% of amount to vote budget as prize
        votes[_voteID].budget += 9000000000000000;

        // Adding 10% to comission
        comission += 1000000000000000;
    }

    function endVoting(uint _voteID) external payable {
        require(votes[_voteID].active, "Voting is not active");
        require(block.timestamp >= votes[_voteID].startDate + 3 days, "End time is not came yet");

        votes[_voteID].winner.transfer(votes[_voteID].budget);

        votes[_voteID].active = false; 
    }

    function withdraw(address payable _to) external ownerOnly {
        require(comission > 0, "Zero balance");
        _to.transfer(comission); // Sends all available comission
    }

    function turnTimeBack(uint _voteID) external ownerOnly { 
        // function to turn back time
        // for testing
        // should be deleted when deploying to production
        votes[_voteID].startDate -= 4 days;
    }

    function isActive(uint _voteID) external view ownerOnly returns(bool) {
        return votes[_voteID].active;
    }

    function votingsCount() external view ownerOnly returns(uint) {
        return lastVoteID;
    }

    function getVoters(uint _voteID) external view ownerOnly returns(address[] memory) {
        return votes[_voteID].voters;
    }

    function getVotes(uint _voteID, address _of) external view ownerOnly returns(uint) {
        return votes[_voteID].votesCount[_of];
    }

    function getWinner(uint _voteID) external view ownerOnly returns(address) {
        return votes[_voteID].winner;
    }

    function getWinnerVotes(uint _voteID) external view ownerOnly returns(uint) {
        return votes[_voteID].votesCount[votes[_voteID].winner];
    }
}
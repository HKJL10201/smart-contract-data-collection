// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract Votings {
    address payable public owner;
    Voting[] public votings;
    uint public votingId;
    uint private commission;

    struct Candidate {
        address payable id;
        uint votes;
    }

    struct Voting {
        uint id;
        uint created;
        bool completed;
        address payable[] voters;
        mapping(uint => Candidate) candidates;
        uint quantityOfCandidates;
        address payable[] winners;
        uint budget;
    }

    constructor() payable {
        owner = payable(msg.sender);
        votingId = 0;
        commission = 0;
    }

    function addVoting() public onlyOwner {votings.push();
        Voting storage voting = votings[votingId];
        voting.id = votingId;
        voting.created = block.timestamp;
        voting.completed = false;
        voting.quantityOfCandidates = 0;
        voting.budget = 0;
        votingId++;
    }

    function getVoting(uint _id) public view returns (uint id, uint created, bool completed, uint candidates, uint budget) {
        Voting storage voting = votings[_id];
        return (voting.id, voting.created, voting.completed, voting.quantityOfCandidates, voting.budget);
    }

    function vote(uint _id, address payable _candidate) public payable {
        Voting storage voting = votings[_id];

        require(!voting.completed, "Voting already completed!");
        require(msg.value >= 0.01 ether, "Wrong amount of ethers!");
        require(msg.sender != _candidate, "You can't vote for yourself");

        uint i = 0;
        bool voted = false;
        while (i < voting.voters.length && !voted) {
            if (voting.voters[i] == msg.sender) {
                voted = true;
            }
            i++;
        }
        require(!voted, "You already voted!");

        voting.voters.push(payable(msg.sender));

        bool foundCandidate = false;
        for (uint j = 0; j < voting.quantityOfCandidates; j++) {
            if (voting.candidates[j].id == _candidate) {
                voting.candidates[j].votes++;
                foundCandidate = true;
                break;
            }
        }
        if (!foundCandidate) {
            uint idCandidate = voting.quantityOfCandidates;
            Candidate storage candidate = voting.candidates[idCandidate];
            candidate.id = payable(_candidate);
            candidate.votes = 1;
            voting.quantityOfCandidates++;
        }

        voting.budget += msg.value;
    }

    function closeVoting(uint _id) public payable {
        Voting storage voting = votings[_id];
        require(block.timestamp - voting.created > 60*60*24*3 , "It hasn't been 3 days");
        require(voting.budget > 0, "There are no budget");
        require(!voting.completed, "Voting already completed");

        // get winners
        uint maxVotes = 0;
        for (uint i = 0; i < voting.voters.length; i++) {
            if (voting.candidates[i].votes == maxVotes) {
                voting.winners.push(payable(voting.candidates[i].id));
            }
            if (voting.candidates[i].votes > maxVotes) {
                maxVotes = voting.candidates[i].votes;
                voting.winners = new address payable[](0);
                voting.winners.push(payable(voting.candidates[i].id));
            }
        }

        // send eth to winner and pay commission
        commission += (voting.budget / 10 * 1);
        for (uint i = 0; i < voting.winners.length; i++) {
            voting.winners[i].transfer(voting.budget / voting.winners.length / 10 * 9);
        }

        // close voting
        voting.completed = true;
    }

    function showCommission() public view onlyOwner returns (uint amount) {
        return commission;
    }

    function withdrawCommission() public payable onlyOwner {
        require(commission > 0, "There are no commission");
        uint _commission = commission;
        commission = 0;
        owner.transfer(_commission);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this");
        _;
    }
}
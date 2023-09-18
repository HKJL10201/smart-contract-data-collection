// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// ====== add more features =====
// 1) chainperson can giveRightToVote() to Voter
// 2) add weight of voter
// 3) emit 2 events

contract Ballot2 {
    
    struct Voter {
        uint weight;
        bool voted;
        uint vote;
    }
    
    struct Proposal {
        string name;
        uint voteCount;
    }
    
    address public chairperson;
    
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    string[] public proposalNames = ["Warodom", "Tanakorn", "Naratorn"];
    uint public numProposals;
    
    uint public closeDate;
    
    event Voted(address sender, uint proposal, uint voteCount);
    event GaveRightToVote(address voter);
    
    constructor() {
        chairperson = msg.sender;
        numProposals = proposalNames.length;
        
        closeDate = block.timestamp + 1 hours;
        
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({name: proposalNames[i], voteCount: 0})
            );
        }
    }
    
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "only chairperson can give right to vote");
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
        
        emit GaveRightToVote(voter);
    }
    
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        require(block.timestamp < closeDate, "The voting is closed");
        
        sender.voted = true;
        sender.vote = proposal;
        
        proposals[proposal].voteCount++;
        
        emit Voted(msg.sender, proposal, proposals[proposal].voteCount);
    }
    
    function winnigProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }
    
    function winnerName() public view returns (string memory) {
        return proposals[winnigProposal()].name;
    }
    
}
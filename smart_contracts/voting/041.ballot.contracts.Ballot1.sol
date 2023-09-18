// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Ballot1 {
    
    struct Voter { 
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
    
    constructor() {
        chairperson = msg.sender;
        numProposals = proposalNames.length;
        
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({name: proposalNames[i], voteCount: 0})
            );
        }
    } 
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender]; 
        require(!sender.voted, "Already voted"); 
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount++; 
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
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting system with delegation feature
/// @author AlinCiprian
/// @notice You can use this contract to implement a decentralized voting system

contract Ballot {
    struct Voter {
        uint32 weight; // weight is acumulated by delegation
        bool voted; // if voted is true, the person have already voted
        address delegate; //the address delegated by the voter
        uint32 vote; // the index of the preffered proposal
    }

    struct Proposal {
        string proposalName;
        uint voteCount;
    }

    uint[] public winningProposals; //This array contains the indexes of the winner/winners
    string[] public winnerNames; // An array that contains the winner/winners names

    mapping(address => Voter) voters;
    Proposal[] public proposals; // An array that contains the proposals which will be voted

    address public chairman;

    constructor(string[] memory proposalNames) {
        chairman = msg.sender;
        voters[chairman].weight = 1;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({proposalName: proposalNames[i], voteCount: 0})
            );
        }
    }

    function giveRightToVote(address _voter) external {
        require(msg.sender == chairman, "Only chairman can give right to vote");
        require(!voters[_voter].voted, "Already voted");
        require(voters[_voter].weight == 0);
        voters[_voter].weight = 1;
    }

    function delegateVote(address _to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Can not delegate if you have already voted");
        require(sender.weight != 0, "You have no right to vote");
        require(_to != msg.sender, "Self-delegation is not allowed");
        Voter storage delegated = voters[_to];
        require(
            delegated.weight != 0,
            "The delegated address does not have the right to vote"
        );

        sender.voted = true;
        sender.delegate = _to;

        if (delegated.voted) {
            proposals[delegated.vote].voteCount += sender.weight;
        } else {
            delegated.weight += sender.weight;
        }
    }

    function vote(uint32 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You do not have the right to vote");
        require(!sender.voted, "Already voted");

        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    function countVotes() external {
        require(
            msg.sender == chairman,
            "Only the chairman can trigger this function"
        );
        uint winningCount = 0;
        // Find the highest number of votes and store it in winningCount
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningCount) {
                winningCount = proposals[p].voteCount;
            }
        }
        // Store in winningProposals the indexes of the  proposals  that have a voteCount equal to winningCount
        // This way we can keep track if we have more proposals with the same number of votes
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount == winningCount) {
                winningProposals.push(i);
            }
        }
        // Based on the indexes above, we store in winnerNames the corespondent names;
        for (uint index = 0; index < winningProposals.length; index++) {
            uint winnerIndex = winningProposals[index];
            winnerNames.push(proposals[winnerIndex].proposalName);
        }
    }

    function getWinners() public view returns (string[] memory) {
        return winnerNames;
    }

    function getProposalNames() public view returns (string[] memory) {
        uint itemCount = proposals.length;
        string[] memory proposalNames = new string[](itemCount);

        for (uint i = 0; i < proposals.length; i++) {
            proposalNames[i] = proposals[i].proposalName;
        }
        return proposalNames;
    }
}

pragma solidity ^0.4.22;

/// @title Ballot
contract Ballot {

    // voter struct
    struct Voter {
        uint weight; // vote weight
        bool voted;  // already voted?
        uint vote;   // index of the voted proposal
    }

    // Proposal struct.
    struct Proposal {
        string name;   // proposal name
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor() public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        proposals.push(Proposal({
            name: "Proposal 1",
            voteCount: 0
            }));

        proposals.push(Proposal({
            name: "Proposal 2",
            voteCount: 0
            }));

        proposals.push(Proposal({
            name: "Proposal 3",
            voteCount: 0
            }));

    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        require(sender.weight > 0, "Not authorized to vote");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view
    returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view
    returns (string winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}
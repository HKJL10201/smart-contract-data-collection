pragma solidity ^0.4.20;

contract Voting {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    function Voting() public {
        chairperson = msg.sender;
    }
    
    //add a proposal which can be voted on
    function addProposal(string proposalName) public {
        proposals.push(Proposal({
            name: string(proposalName),
            voteCount: uint(0)
        }));
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) public {
        require((msg.sender == chairperson) && !voters[voter].voted);

        Voter memory _voter = Voter({
            voted: bool(false),
            vote: uint(0)
        });

        voters[voter] = _voter;
    }

    /// Give your vote to proposal `proposals[proposal].name`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];

        require(!sender.voted && proposal < proposals.length);

        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += 1;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view returns (uint _winningProposal) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                _winningProposal = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view returns (string _winnerName) {
        _winnerName = proposals[winningProposal()].name;
    }
}
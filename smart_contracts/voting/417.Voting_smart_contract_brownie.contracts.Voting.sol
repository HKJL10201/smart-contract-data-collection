// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation.
contract Voting {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote; // index of the voted proposal
    }
    // This is a type for a single proposal.
    struct Proposal {
        string name; // string name
        uint256 voteCount; // number of accumulated votes
    }
    address public chairperson;
    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;
    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint256 i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address[] memory voter) external {
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        // This used to consume all gas in old EVM versions, but
        // not anymore.
        // It is often a good idea to use `require` to check if
        // functions are called correctly.
        // As a second argument, you can also provide an
        // explanation about what went wrong.
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        for (uint256 j = 0; j < voter.length; j++) {
            require(!voters[voter[j]].voted, "The voter already voted.");
            require(
                voters[voter[j]].weight == 0,
                "One, or some, or all of the address already have the right to vote"
            );
            voters[voter[j]].weight = 1;
        }
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) external {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        Voter storage delegate_ = voters[to];
        // Voters cannot delegate to accounts that cannot vote.
        require(
            delegate_.weight >= 1,
            "Voters cannot delegate to accounts that cannot vote"
        );
        require(
            voters[to].delegate == address(0),
            "You can't delegate to someone who already delegated."
        );

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender]`.
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint256 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// Returns the maximum vote a proposal has got

    function getMaxVoteCount() public view returns (uint256 maxVoteCount) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                maxVoteCount = winningVoteCount;
            }
        }
    }

    // Calls getMaxVoteCount() function to get the max vote count
    // and then returns the name of the winner or if it's a tie
    // it returns a tie message

    function checkIfTieOrNot() external view returns (string memory wName) {
        uint256 counter = 0;
        for (uint256 x = 0; x < proposals.length; x++) {
            if (getMaxVoteCount() > 0) {
                if (proposals[x].voteCount == getMaxVoteCount()) {
                    counter++;
                    if (counter >= 2) {
                        wName = "Nobody was elected because the election concluded with a tie.";
                    }
                    if (counter == 1) {
                        wName = proposals[x].name;
                    }
                }
            } else {
                revert("Something went wrong... Maybe nobody voted.");
            }
        }
    }
}

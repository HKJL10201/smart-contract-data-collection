pragma solidity >=0.4.22 <0.7.0;

/** @dev Original Ballot.sol code from Remix with my personal notes added
  */

/// @title (Whatever to the left means...) Voting with delegation.

// Creating a smart contract called 'Ballot'

/// "The idea is to create one contract per ballot, providing a short
/// for each option. Then the creator of the contract who serves as
/// chairperson will give the right to vote to each address
/// individually.

/// "The persons behind the addresses can then choose to either
/// vote themselves or to delegate their vote to a person they
/// trust."

contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint weight;         // weight is accumulated by delegation
        bool voted;          // if true, that person already voted
        address delegate;    // person delegated to
        uint vote;           // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;        // short name (up to 32 bytes)
        uint voteCount;      // number of accumulated votes
    }

    address public chairperson;

    // This declares a state variable that
    // stores a 'Voter' struct for each possible address.

    // mapping 'address' to 'Voter' struct, creating a new
    // variable for each address,each stored in variable
    // called 'voters', where you index an indy voter
    // from 'voters' array
    mapping(address => Voter) public voters;

    // A dynamically-sized array of 'Proposal' structs.
    // array is named 'proposals', which is composed of
    // 'Proposal' structs
    Proposal[] public proposals;

    /// Create a new ballot to choose one of 'proposalNames'.
    constructor(bytes32[] memory proposalNames) public {
        // chairperson is the sender of transaction
        chairperson = msg.sender;
        // from 'voters' array, index chairperson, select
        // their weight and set it equal to one
        voters[chairperson].weight = 1;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.

        // for loop that iterates over every uint if current
        // iteration is the first iteration, and if the
        // iteration is less than the length of the
        // proposalNames array, also adding a +1 counter
        // to the the end of the iteration index (i)

        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) public {
        // If the first argument of `require` evaluates
        // to `false`, exeuction terminates and all
        // changes to he state and to Ether balancse
        // are reverted.
        // This is to consume all gas in old EVM versions,
        // but not anymore.
        // It is often a good idea to use `require` to
        // check if // functions are called correctly.
        // As a second argument, you can also provide an
        // explanation about what went wrong.
        require(
            msg.sender == chairperson,
            "Only chairperson can give the right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) public {
        // assigns reference
        // Assigning `Voter` struct to new `sender`
        // variable, which is saved in `storage`
        // , the variable `sender` is made of
        // the `msg.sender` property of `voters` array
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        // chairperson cannot delegate to themselves
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
            // While there are delegated voters not equal
            // to the first address, the delegated voters
            // are set equal to the variable `to`.
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            // Again, chairperson cannot self-delegate, which
            // would initiate a loop of Self-delegation
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if(delegate_.voted) {
            // If the delegate already voted,
            // i.e.
            // delegate voter = proposals[delegate_]
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // if delegate_.voted == false...
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        // Setting sender as `already voted`
        sender.voted = true;
        // Setting sender vote as a `proposal`
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    // NOTE: function is public but only viewable
    // and not callable on the Ethereum blokchain.
    function winningProposal() public view
        returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;

        // Setting `p` equal to each proposal in
        // `proposals[i]` and using `p` to
        // count each voteCount in
        // `proposals[p].voteCount`
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the porposals array and then
    // returns the name of the winner
    function winnerName() public view
        // setting a must return output variable
        returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}

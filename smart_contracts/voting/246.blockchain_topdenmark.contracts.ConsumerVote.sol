pragma solidity ^0.4.22;

/// @title Voting with delegation.
contract ConsumerVote {

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted farm
    }

    // This is a type for a single farm.
    struct Farm {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson; //one node who made this voting 

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Farm` structs.
    Farm[] public farms;

    /// Create a new ConsumerVote to choose one of `farmNames`.
    constructor(bytes32[] memory farmNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // For each of the provided farm names,
        // create a new farm object and add it
        // to the end of the array.
        for (uint i = 0; i < farmNames.length; i++) {
            // `Farm({...})` creates a temporary
            // Farm object and `farms.push(...)`
            // appends it to the end of `farms`.
            farms.push(Farm({
                name: farmNames[i],
                voteCount: 0
            }));
        }
    }

    // Give `voter` the right to vote.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) public {
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
        Voter storage sender = voters[msg.sender];
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

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            farms[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to farm `farms[farm].name`.
    function vote(uint farm) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = farm;

        // If `farm` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        farms[farm].voteCount += sender.weight;
    }

    /// @dev Computes the winning farm taking all
    /// previous votes into account.
    function winningFarm() public view
            returns (uint winningFarm_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < farms.length; p++) {
            if (farms[p].voteCount > winningVoteCount) {
                winningVoteCount = farms[p].voteCount;
                winningFarm_ = p;
            }
        }
    }

    // Calls winningFarm() function to get the index
    // of the winner contained in the farms array and then
    // returns the name of the winner
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = farms[winningFarm()].name;
    }
}
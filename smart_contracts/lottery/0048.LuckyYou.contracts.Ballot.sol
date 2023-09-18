pragma solidity>=0.4.22<0.7.0;

// import "./Utilslib.sol";

contract Ballot {
    
    // represent single voter
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    // a single proposal
    struct Proposal {
        // not string; can use web3.utils.fromAscii(val, 32) or web3.utils.toAscii(val) to do the transformation
        bytes32 name; // short name (up to 32 bytes)
        uint voteCount;
    }
    
    address public chairperson;
    
    // state variable stores a Voter for each address
    mapping(address => Voter) public voters;

    // dynamic sized array
    Proposal[] public proposals;

    constructor (bytes32[] memory proposalNames) public {
    // constructor () public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        // bytes32[] memory proposalNames;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(
                Proposal({
                    name: proposalNames[i],
                    voteCount: 0
                })
            );
        }
    }

    function giveRightsToVoters(address[] memory addrs) public {
        for (uint i=0; i < addrs.length; i++) {
            giveRightToVote(addrs[i]);
        }
    }

    // can only be called by chairman
    function giveRightToVote(address voter) public {
        // require here is like asseret
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );

        require(voters[voter].weight == 0, "permisstion already granted");
        voters[voter].weight = 1;
    }

    // for someone who would like to appoint others to vote for him. (delegation)
    function delegate(address to) public {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");

        require(to != msg.sender, "self-delegation is disallowed.");
        
        // forward delegation if 'to' also delgated
        // dangers loop
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, "Found loop delegation.");
        }

        sender.voted = true;
        sender.delegate = to;

        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // if the delegate already voted,
            // directly add the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // if the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }


    // vote to proposal
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;

        // if 'poroposal' is out of range of the array,
        // this will throw automatically and revert all changes.
        require(proposal < proposals.length, "exceed limit");
        proposals[proposal].voteCount += sender.weight; 
    }


    // compute the winning proposal
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        bool has_winner = false;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                has_winner = true;
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        require(has_winner, "no voting happened yet!");
    }

    // getcall winningProposal name
    function winnerName() public view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
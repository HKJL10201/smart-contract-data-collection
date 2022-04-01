// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
   
    struct Voter {
        uint weight; // Weight is accumulated by Delegation
        bool voted;  // If true then that Person already voted
        address delegate; // Person delegated to
        uint vote;   // Index of the voted Proposal
    }

    struct Proposal {
        /* If the Limit of the Length matched a certain Number of Bytes it should be used a bytes1 to bytes32 because they are cheaper in Fees */
        string name;   // Short Name of Proposal
        uint voteCount; // Number of accumulated Votes
    }

    /* Keyword public: The Variable is visible in the Smart Contract and also Outside (for Example in Front End) */
    address public chairperson;

    /* Map with Key as address and Value as Voter (Voter is a Structure) */
    /* Each User of this Smart Contract get his own Mapping in this Map */
    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    /* Constructor taking an Array as an Argument to deploy the Smart Contract */
    constructor(string[] memory proposalNames) {
        /* Value of msg.sender contains the Person who deployed the Smart Contract */
        chairperson = msg.sender;
        
        /* Setting the Weight of a Voter with the Address of the Chairperson to 1 */
        voters[chairperson].weight = 1;

        /* Mapping over the Array proposalNames an creating a new Proposal for each of them */
        for (uint i = 0; i < proposalNames.length; i++) {
            /* 'Proposal({...})' creates a temporary Proposal Object (Proposal is a Structure) */
            /* 'proposals.push(...)' appends it to the end of the Array 'proposals' */
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    /* Give Voter the Right to vote on this ballot */
    /* May only be called by Chairperson */
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only Chairperson can give Right to Vote.");
        /* Getting the Reference of a Voter and checking his voted Flag (must be inital false) */
        require(!voters[voter].voted, "The voter already voted.");
        /* Checking if Voter have not already given his Right to Vote */
        require(voters[voter].weight == 0);
        /* Setting Weight to be 1 and so allow the Voter to vote and also be  allowed to delegate the Vote */
        voters[voter].weight = 1;
    }

    /* Delegate the Vote from Voter to the Voter 'to' */
    function delegate(address to) public {
        /* Get Reference of current Voter (who is sending this Transaktion) */
        Voter storage sender = voters[msg.sender];
        /* Checking if Voter has not already voted */
        require(!sender.voted, "You already voted.");
        /* Checking for Self-Delegation */
        require(to != msg.sender, "Self-delegation is disallowed.");

        /* Checking that the Delegate to give the Vote to does not have an empty Address */
        /* If the Address is not empty the Voter which should be delagted to has given his Vote to another Voter (also deleagted his Vote) */
        /* Looping so long until a delagted Voter is found who has not given his Vote to another Voter */
        while (voters[to].delegate != address(0)) {
            /* Reassign the Address of delegated to because the Voter has given his Vote to another Voter */
            to = voters[to].delegate;
            /* Found a Loop in the delegation which is not allowed */
            require(to != msg.sender, "Found Loop in Delegation.");
        }
        /* Set the Voter as voted */
        sender.voted = true;
        /* Set the Delegation of the Voter */
        sender.delegate = to;
        
        /* Increasing the Vote Count of the Delegate */
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            /* If the Delegate already voted directly add to the Number of Votes */
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the Delegate did not vote yet add to his Weight */
            delegate_.weight += sender.weight;
        }
    }

    /* Giving the current Vote (including Votes delegated to the current Voter) to Proposal 'proposals[proposal].name' */
    /* Uint proposal work with Indexes : 0 => Voter1, 1 => Voter2, 2 => Voter3 etc. */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        /* Checking if Weight of Voter is not 0 because if it is 0 they can not vote */
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        /* Set Vote to the Proposal the Voter voted for */
        sender.vote = proposal;

        /* Increasing the Vote Count for the Voter who the current Voter voted for */
        /* If 'proposal' is out of the Range of the array this will throw automatically and revert all Changes */
        proposals[proposal].voteCount += sender.weight;
    }

    /* Computes the winning Proposal taking all previous Votes into Account */
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            /* Recalculating the winning Proposal (on the highest Value in this Loop) */
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    /* Calls winningProposal() Function to get the Index of the Winner contained in the Array proposals */
    /* Return the Name of the Winner */
    function winnerName() public view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }

    function greet() public view returns (address) {
        return chairperson;
    }
}

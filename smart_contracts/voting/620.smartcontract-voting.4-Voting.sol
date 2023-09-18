// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    // This declares a new complex type which will be used for variables later. It will represent a single voter.
    struct Voter {
        uint weight; // Weight is accumulated by delegation.
        bool voted; // If true, that person already voted.
        address delegate; // Person(address) delegated to.
        uint vote; // Index of the voted proposal.
    }

    // This is a type for a single proposal (candidate).
    struct Proposal {
        bytes32 name; // Short name (up to 32 bytes).
        uint voteCount; // Number of accumulated votes.
    }

    address public chairperson;

    // This declares a state variable that stores a "Voter" struct for each possible address.
    mapping(address => Voter) public voters;

    // A dinamically-sized array of "Proposal" structs.
    Proposal[] public proposals;

    // Create a new ballot to choose one of "proposalNames".
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;

        voters[chairperson].weight = 1;
        
        // For each of the provided proposal names, create a new peoposal object and add it to the of the array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // "Proposal({...})" creates a temporary Propsal object and "proposal.push(...) appends it to the end of "proposals""
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Give the "voter" the right to vote on this ballot. May only be called by the "chairperson".
    function giveRightToVote(address voter) public {
        // If the first argument of "require" evaluates to "false", the execution terminates and all changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use "require" to check if functions are called correctly. As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == chairperson, "Only the chairperson can give the right to vote.");
        require(!voters[voter].voted, "The voter already voted.");
        require(voters[voter].weight == 0);

        voters[voter].weight = 1;
    }

    // Delegate yout vote to the voter "to"
    function delegate(address to) public {
        // Assigns reference
        Voter storage sender = voters[msg.sender];
        
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        // Forward the delegation as long as "to" also delegated. In general, such loops are very dangerous, because if they run too long, they might need more gas than is avaible in a block. 
        // In this case, the delegation will not be executed, but in other situations, such loops might cause a contract to get "stuck" completely.
        while(voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            
            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        //Since "sender" is a reference, this modifies "voters[msg.sender].voted"
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_= voters[to];

        if(delegate_.voted) {
            // If the delegate already voted, ditectely add to the number of votes.
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet, add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];

        require(sender.weight != 0, "You have no right to vote.");
        require(!sender.voted, "You have already voted.");

        sender.voted = true;
        sender.vote = proposal;

        // If "porposal" is out of the rande of the array, this will throw automatically and revert all changes.
        proposals[proposal].voteCount += sender.weight;
    }

    // It computes the winning porposal taking all previous votes into account.
    function winningProposal() public view returns(uint winningProposal_) {
        uint winningVoteCount = 0;

        for(uint p = 0; p < proposals.length; p++) {
            if(proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index of the winner contained in the proposals array and then return the name of the winner.
    function winnerName() public view returns(bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//If you try to compile it 
contract Ballot {

struct Voter{
    uint weight; // weight is accumulated by delegation, if 0, then no right to vote
    bool voted; // person voted or not
    address delegate; // person delegated to
    uint vote; // index of the voted proposal
}

struct Proposal{
    string name; // short name (up to 32 bytes)
    uint voteCount; // represents votes that the proposal received
}

address public chairperson; // only chairperson can submit proposals to be voted
mapping (address => Voter) public voters;

Proposal[] public proposals;

constructor(string[] memory proposalNames){
chairperson = msg.sender; // Whoever deploying the contract will be the chairperson
voters[chairperson].weight = 1;

    // Initializing Proposals with the vote count 0
    for(uint i = 0; i < proposalNames.length; i++){
            proposals.push(Proposal({
                name: proposalNames[i],voteCount:0
            }));
        }
    }


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

        /**
            Delegate your vote to the voter 'to'.
            Means that msg.sender(the person who's currently connecting with the contract) will vote to the person with address 'to'.
         */
        function delegate(address to) public {
            Voter storage sender = voters[msg.sender];
            require(!sender.voted, "You already voted.");
            require(to != msg.sender, "Self-delegation is disallowed.");

            /* Simple explanation of the while loop
            Let's assume that you voted for someone(address b).              a => b
            And that person b voted for another person with address c.       a => b => c
            That person c voted for someone else with address d              a => b => c => d
            So we need to assign person a's vote to person d, not person b.
            While loop goes and goes until it reaches address 0 and when reaches it stops and we get final vote to address as d.
            **/
            while (voters[to].delegate != address(0)) {
                to = voters[to].delegate;

                // We found a loop in the delegation, not allowed.
                require(to != msg.sender, "Found loop in delegation.");
            }
            sender.voted = true;
            sender.delegate = to;
            Voter storage delegate_ = voters[to];
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

      
        function vote(uint proposal) public {
            Voter storage sender = voters[msg.sender];
            require(sender.weight != 0, "Has no right to vote");
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = proposal;

            // If 'proposal' is out of the range of the array,
            // this will throw automatically and revert all
            // changes.
            proposals[proposal].voteCount += sender.weight;
        }

      
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

       
        function winnerName() public view
                returns (string memory winnerName_)
        {
            winnerName_ = proposals[winningProposal()].name;
        }
    }


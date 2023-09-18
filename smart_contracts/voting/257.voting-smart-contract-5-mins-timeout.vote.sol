// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Ballot {

    uint startTime = block.timestamp;

   
    struct Voter {
        uint weight; 
        bool voted;  
        address delegate; 
        uint vote;   
    }

    struct Proposal {
        string name;   
        uint voteCount; 
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;


    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {

            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
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


    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
          require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {

            proposals[delegate_.vote].voteCount += sender.weight;
        } else {

            delegate_.weight += sender.weight;
        }
    }

    modifier voteEnded(){
        if(block.timestamp > startTime + (5 * 1 minutes)){
            revert("Voting Time expired. Voting was only for 5 minutes.");
        }
        _;
    }

    function vote(uint proposal) public voteEnded{
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

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

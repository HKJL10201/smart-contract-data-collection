pragma solidity 0.6.12;

contract Ballot {
    struct Voter {
        bool voted;
        uint vote;
        uint weight;
    }

    struct Proposal {
    bytes32 name; //name of each proposal
    uint voteCount; // Number of accumulated Votes
    }

    Proposal[] proposals;

    mapping(address => Voter ) voters; //voters get address as a key and Voter for a value 
    
    address public chairperson

    constructor (bytes32[] memory proposalNames) {

        chairperson = msg.sender;

        voters[chairperson].weight = 1;

        for (uint i=0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    //Function to atuenticate Voter
    function allowVote(address voter) public {
        require( msg.sender == chairperson, "Only the chairperson has access");
        require(!voters[voter].voted, "This Voter has already voted"); 
        require(voters[voter].weight == 0 );

        voters[voter].weight = 1
    }

    function vote (uint proposal) public{
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, 'Has no right to vote');
        require(!sender.voted, "Has Voted Already");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight
    }

    // Functions for showing the results

    //1.Function that shows the winning proposal (index)
    function winningProposal () public view returns(uint winningProposal_) {

        uint winningVoteCount = 0;
        for(uint i =0; i < proposals.length; i++) {
            if(proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[1].voteCount;
                winningProposal = i;
            }   
        }
    }

    //2.Function that shows the winner by name 
    function winnersName () public view returns (bytes32 _winner) {
        _winner = proposals[winningProposal()].name;
    }
}

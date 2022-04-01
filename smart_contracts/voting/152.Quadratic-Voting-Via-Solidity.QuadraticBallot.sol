pragma solidity >=0.4.22 <0.7.0;

/** 
 * @title QuadraticBallot
 * @dev Implements voting process along with vote delegation
 */
contract QuadraticBallot {
   
    struct Voter {
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint[] vote;   // quadratic vote
        uint weight;    // weight of voter, NOTE: this is not the weight of the proposal
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;
    uint public budgetPerPerson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     * @param budget voting budget each voter has
     */
    constructor(bytes32[] memory proposalNames, uint budget) public {
        chairperson = msg.sender;
        budgetPerPerson = budget;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function assignVoter(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can assign Voters."
        );
        require(
            !voters[voter].voted,
            "The voter has already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }


    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal the credits of each proposal that the voter distributes
     */
    function vote(uint[] memory proposal) public {
        Voter storage sender = voters[msg.sender];

        //Validate
        require(proposal.length == proposals.length, "Invalid proposal array Pass Through");
        require(sender.weight != 0, "Voter has no weight to vote!");
        require(!sender.voted, "Voter has already voted!");

        uint totalCredits = 0;
        for (uint proposalIndex = 0; proposalIndex < proposal.length; proposalIndex++) {
            totalCredits += proposal[proposalIndex] * proposal[proposalIndex];
        }
        require(totalCredits <= budgetPerPerson, "Invalid vote credits!");

        //Mark this sender as voted!
        sender.voted = true;
        sender.vote = proposal;

        //update proposal vote count here~
        for (uint proposalIndex = 0; proposalIndex < proposal.length; proposalIndex++) {
            proposals[proposalIndex].voteCount += sender.weight * proposal[proposalIndex];
        }
    }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint maxCount = 0;
        for (uint p = 0; p < proposals.length; p++){
            if (proposals[p].voteCount > maxCount) {
                maxCount = proposals[p].voteCount;
                winningProposal_ = p;
            }

        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}

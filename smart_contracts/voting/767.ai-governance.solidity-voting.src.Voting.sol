// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Governance {

    // Represents a proposal for voting
    struct Proposal {
        string description;   // Description or title of the proposal
        uint256 yesVotes;     // Total weight of 'yes' votes
        uint256 noVotes;      // Total weight of 'no' votes
        uint256 endTime;      // End timestamp for voting on the proposal
        bool closed;          // Whether voting on the proposal is closed or not
    }

    // Represents an individual voter's vote and its attributes
    struct Voter {
        uint256 weight;       // Weight of the vote (often tied to token amount)
        bool voted;           // Flag to check if the voter has already voted on the proposal
        bool voteChoice;      // Choice of vote: true for 'yes', false for 'no'
    }

    // Mapping to store all proposals by their ID
    mapping(uint256 => Proposal) public proposals;

    // Nested mapping to store votes on proposals by their voter's address
    mapping(uint256 => mapping(address => Voter)) public proposalVotes; // proposalID => address => Voter

    // Counter to track the total number of proposals
    uint256 public proposalCount = 0;

    // The ERC20 token used for voting (often representing governance power)
    IERC20 public govCoin;

    /**
     * @dev Constructor initializes the governance contract with a given ERC20 token for voting
     * @param _govCoin Address of the ERC20 token to be used for voting
     */
    constructor(address _govCoin) {
        govCoin = IERC20(_govCoin);
    }

    /**
     * @dev Create a new proposal for voting
     * @param _description Description or title of the proposal
     * @param _duration Duration in seconds for which the voting will remain open
     */
    function createProposal(string memory _description, uint256 _duration) external {
        proposals[proposalCount] = Proposal({
            description: _description,
            yesVotes: 0,
            noVotes: 0,
            endTime: block.timestamp + _duration,
            closed: false
        });

        proposalCount++;
    }

    /**
     * @dev Cast a vote on a specific proposal
     * @param _proposalId ID of the proposal on which to vote
     * @param _choice Boolean choice of vote: true for 'yes', false for 'no'
     * @param _amount Amount of ERC20 tokens to be locked, representing vote weight
     */
    function vote(uint256 _proposalId, bool _choice, uint256 _amount) external {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        require(!proposalVotes[_proposalId][msg.sender].voted, "Already voted on this proposal");
        require(!proposals[_proposalId].closed, "Voting is closed for this proposal");
        require(proposals[_proposalId].endTime > block.timestamp, "Proposal voting time expired");

        // Transfer and lock tokens for voting
        govCoin.transferFrom(msg.sender, address(this), _amount);  

        proposalVotes[_proposalId][msg.sender] = Voter({
            weight: _amount,
            voted: true,
            voteChoice: _choice
        });

        // Increment the vote count based on the choice
        if (_choice) {
            proposals[_proposalId].yesVotes += _amount;
        } else {
            proposals[_proposalId].noVotes += _amount;
        }
    }

    /**
     * @dev Close the voting on a specific proposal. Only callable after voting duration has expired
     TODO: return the tokens to the voters
     * @param _proposalId ID of the proposal to close voting for
     */
    function closeVoting(uint256 _proposalId) external {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        require(!proposals[_proposalId].closed, "Voting is already closed for this proposal");
        require(proposals[_proposalId].endTime <= block.timestamp, "Proposal voting time not yet expired");

        proposals[_proposalId].closed = true;
    }
}

// Simplified ERC20 interface for voting purposes
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

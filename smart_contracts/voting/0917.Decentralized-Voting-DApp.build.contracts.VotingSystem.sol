pragma solidity ^0.8.0;

contract VotingSystem {
    struct Proposal {
        string title;
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;

    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => address[]) public votersForProposal;
    address public owner;

    event ProposalCreated(uint proposalIndex, string title, string description);
    event ProposalRemoved(uint proposalIndex);
    event Voted(uint proposalIndex, address voter);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    modifier proposalExists(uint proposalIndex) {
        require(proposalIndex < proposals.length, "Proposal does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createProposal(
        string memory title,
        string memory description
    ) public onlyOwner {
        proposals.push(
            Proposal({title: title, description: description, voteCount: 0})
        );
        emit ProposalCreated(proposals.length - 1, title, description);
    }

    function removeProposal(
        uint proposalIndex
    ) public onlyOwner proposalExists(proposalIndex) {
        emit ProposalRemoved(proposalIndex);

        // Delete votes for the removed proposal
        address[] storage voters = votersForProposal[proposalIndex];
        for (uint i = 0; i < voters.length; i++) {
            delete hasVoted[proposalIndex][voters[i]];
        }

        // Shift proposals and their votes
        for (uint i = proposalIndex; i < proposals.length - 1; i++) {
            proposals[i] = proposals[i + 1];
            votersForProposal[i] = votersForProposal[i + 1];
            for (uint j = 0; j < votersForProposal[i].length; j++) {
                address voter = votersForProposal[i][j];
                hasVoted[i][voter] = hasVoted[i + 1][voter];
            }
        }

        proposals.pop();
    }

    function vote(uint proposalIndex) public proposalExists(proposalIndex) {
        require(
            !hasVoted[proposalIndex][msg.sender],
            "You have already voted on this proposal"
        );
        proposals[proposalIndex].voteCount++;
        hasVoted[proposalIndex][msg.sender] = true;
        votersForProposal[proposalIndex].push(msg.sender);
        emit Voted(proposalIndex, msg.sender);
    }

    function getProposal(
        uint proposalIndex
    )
        public
        view
        proposalExists(proposalIndex)
        returns (string memory title, string memory description, uint voteCount)
    {
        return (
            proposals[proposalIndex].title,
            proposals[proposalIndex].description,
            proposals[proposalIndex].voteCount
        );
    }

    function getProposalsCount() public view returns (uint) {
        return proposals.length;
    }
}

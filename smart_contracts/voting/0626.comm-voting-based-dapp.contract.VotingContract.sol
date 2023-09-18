pragma solidity >0.8.9;

interface IToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
    function totalSupply() external returns (uint256);
}

contract VotingContract {
    struct Proposal {
        string description;
        uint256 yesCount;
        uint256 noCount;
        uint256 timestamp;
    }

    //address public votingToken;
    IToken public votingToken;
    Proposal[] public proposals;
    uint256 public proposalCount;

    mapping(address => mapping(uint256 => bool)) private hasVoted;
    mapping(uint256 => bool) public resultProposal;

    event CreateProposal(uint256);
    event CastVote(address, uint256, bool);
    event Finalize(uint256, bool);

    modifier checkProposalEnded(uint256 proposalId) {
        require(block.timestamp < proposals[proposalId].timestamp, "Proposal is ended");
        _;
    }

    constructor(address _votingToken) {
        proposalCount = 0;
        votingToken = IToken(_votingToken);
    }

    function createProposal(string memory _description) public {
        votingToken.transferFrom(msg.sender, address(this), 20);
        Proposal memory proposal = Proposal(
            _description,
            0,
            0,
            block.timestamp + 5 minutes // 2 minutes
        );
        ++proposalCount;
        proposals.push(proposal);
        emit CreateProposal(proposalCount);
    }

    function castVote(uint256 proposalId, bool isApproved) public checkProposalEnded(proposalId) {
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        uint256 totalToken = votingToken.balanceOf(msg.sender);
        if (isApproved) {
            proposals[proposalId].yesCount += totalToken;
        } else {
            proposals[proposalId].noCount += totalToken;
        }
        hasVoted[msg.sender][proposalId] = true;
        emit CastVote(msg.sender, proposalId, isApproved);
    }

    function finalizeProposal(uint256 proposalId) public {
        require(block.timestamp >= proposals[proposalId].timestamp, "Not ended");
        uint256 yesCount = proposals[proposalId].yesCount;
        uint256 totalSupply = votingToken.totalSupply();
        uint256 totalYesVote = (yesCount / totalSupply) * 100;
        if (totalYesVote > 50) {
            resultProposal[proposalId] = true;
        } else {
            resultProposal[proposalId] = false;
        }
        emit Finalize(proposalId, resultProposal[proposalId]);
    }
}

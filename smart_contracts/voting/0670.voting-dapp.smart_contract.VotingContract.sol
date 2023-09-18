// SPDX-License-Identifier: MIT
pragma solidity > 0.8.9;

interface IToken {
    function transferFrom(address, address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function balanceOf(address) external returns(uint256);
    function totalSupply() external returns(uint256);
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
    mapping(uint256 => uint256) public resultProposal;

    event ECreateProposal(uint256);
    event CastVote(address, uint256);
    event EFinalize(uint256, uint256);

    modifier checkProposalEnded(uint256 proposalId) {
        require(block.timestamp < proposals[proposalId].timestamp, "Proposal is ended");
        _;
    }

    constructor(address _votingToken) {
        proposalCount = 0;
        votingToken = IToken(_votingToken);
    }

    function createProposal (string memory _description) public {
        votingToken.transferFrom(msg.sender, address(this), 20 * 10 ** 18);
        Proposal memory propos = Proposal(
            _description,
            0,
            0,
            block.timestamp + 1 minutes
        );
        ++proposalCount;
        proposals.push(propos);
        emit ECreateProposal(proposalCount);
    }

    function hasVotedForProposal(address sender, uint256 proposalId) public view returns (bool) {
        return hasVoted[sender][proposalId];
}

    
    function castVote(uint256 proposalId, bool isApprove) public checkProposalEnded(proposalId) {
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        uint256 totalToken = votingToken.balanceOf(msg.sender);
        if (isApprove) {
            proposals[proposalId].yesCount += totalToken;
        }
        else {
            proposals[proposalId].noCount += totalToken;
        }
        hasVoted[msg.sender][proposalId] = true;
        emit CastVote(msg.sender, proposalId);
    }

    function finalizeProposal(uint256 proposalId) public {
        require(block.timestamp >= proposals[proposalId].timestamp, "Not ended");
        uint256 yesCount = proposals[proposalId].yesCount;
        uint256 totalSupply = votingToken.totalSupply();
        uint256 totalYesVoted = yesCount / totalSupply * 100;
        if (totalYesVoted > 50) {
            resultProposal[proposalId] = 1;
        } else {
            resultProposal[proposalId] = 2;
        }
        emit EFinalize(proposalId, resultProposal[proposalId]);
    }
}
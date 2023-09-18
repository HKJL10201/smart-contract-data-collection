pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

contract Vote {
    struct Proposal {
        uint votesCount;
        string content;
    }

    Proposal[] public proposals;
    // mapping(address => bool[]) public voted;
    address public owner;
    bool public isEnded = false;

    constructor() {
        owner = msg.sender;
    }

    event ProposalSubmitted(address proposer, string content);
    event VoteOn(address voter, uint idx);
    event VoteEnd(uint[] winningProposals);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function propose(string memory _content) public {
        proposals.push(Proposal(0, _content));
        emit ProposalSubmitted(msg.sender, _content);
    }

    function vote(uint256 _idx) public {
        // require(voted[msg.sender][_idx] == false, "Already voted. An address can only vote once");
        proposals[_idx].votesCount += 1;
        emit VoteOn(msg.sender, _idx);
    }

    function endVote() public onlyOwner returns (uint[] memory) {
        uint[] memory winningProposals = new uint[](proposals.length);
        uint maxVoteCount = getMaxVotesCount();

        for (uint i=0; i < proposals.length; i++) {
            if (proposals[i].votesCount == maxVoteCount) {
                winningProposals[i] = 1;
            }
        }
        emit VoteEnd(winningProposals);
        isEnded = true;
        return winningProposals;
    }

    function clearProposals() public onlyOwner {
        require(isEnded, "Can only clear proposals after the voting is ended.");
        delete proposals;
        isEnded = false;
    }

    function getMaxVotesCount() private view returns (uint) {
        uint maxVotesCount = 0;
        for (uint i=0; i < proposals.length; i++) {
            if (proposals[i].votesCount > maxVotesCount) {
                maxVotesCount = proposals[i].votesCount;
            }
        }
        return maxVotesCount;
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }
}

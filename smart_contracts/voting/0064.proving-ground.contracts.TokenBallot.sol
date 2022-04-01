pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

import "./IERC20Token.sol";
import "./BallotProposal.sol";

contract TokenBallot is Ownable {

  string public name;
  string public infoUrl;

  IERC20Token public token;

  uint256 public startBlock;
  uint256 public endBlock;

  address public finalizationDelegate;


  mapping (address => BallotProposal) public proposalsMap;

  BallotProposal[] public proposalsArray;

  uint8 public finalizedProposalsCount;
  bool public votesFinalized;

  uint256 public votesCount;

  modifier onlyIfAcceptingVotes() {
    assert(block.number >= startBlock);
    assert(block.number <= endBlock);
    _;
  }

  modifier onlyBeforeVotingStarts() {
    assert(block.number < startBlock);
    _;
  }

  modifier onlyAfterVotingEnded() {
    assert(block.number > endBlock);
    _;
  }

  function TokenBallot(string _name, IERC20Token _token , uint256 _startBlock, uint256 _endBlock, address _delegate, string _infoUrl) {
    assert(_startBlock >= block.number);
    assert(_endBlock > _startBlock);
    token = _token;
    startBlock = _startBlock;
    endBlock = _endBlock;
    name = _name;
    finalizationDelegate = _delegate;
    infoUrl = _infoUrl;

    BallotCreatedEvent(token, name, startBlock, endBlock, infoUrl);
  }

  event BallotCreatedEvent(address indexed token, string name, uint256 startBlock, uint256 endBlock, string infoUrl);

  function addProposal(BallotProposal _proposal) external onlyOwner onlyBeforeVotingStarts {
    proposalsMap[address(_proposal)] = _proposal;
    proposalsArray.push(_proposal);
    ProposalAddedEvent(_proposal);
  }

  event ProposalAddedEvent(address proposal);

  // array iteration helper
  function proposalsCount() external constant returns (uint256) {
    return proposalsArray.length;
  }

  // this needs to be called by the ballot delegate or owner
  // can also be executed by a server-side script
  function finalizeProposal (
    BallotProposal _proposal,
    uint256 _voters,
    uint256 _votedTokens,
    uint256 _allVotedTokens) external onlyAfterVotingEnded {

    if (msg.sender != finalizationDelegate && msg.sender != owner)
      throw;

    var proposal = proposalsMap[_proposal];

    assert(proposal != address(0));
    assert(!proposal.finalized());

    proposal.finalizeResults(_voters,_votedTokens,_allVotedTokens);

    finalizedProposalsCount += 1;

    if (finalizedProposalsCount == proposalsArray.length) {
      votesFinalized = true;
      BallotFinalizedEvent(_allVotedTokens);
    }

    ProposalFinalizedEvent(proposal, _voters, _votedTokens, _allVotedTokens);
  }

  event ProposalFinalizedEvent(address indexed proposal, uint256 voters, uint256 votedTokens, uint256 allVotedTokens);

  event BallotFinalizedEvent(uint256 allVotedTokens);

  function vote(BallotProposal _proposal) external onlyIfAcceptingVotes {

     // only token holder may vote
     assert (token.balanceOf(msg.sender) > 0);

     var proposal = proposalsMap[_proposal];
     proposal.vote(msg.sender);

     votesCount += 1;

     VoteEvent(proposal, msg.sender);
  }

  event VoteEvent(address indexed proposal, address voter);


  function undoVote(BallotProposal _proposal) external onlyIfAcceptingVotes {

    // only token holder may unvote
    assert(token.balanceOf(msg.sender) > 0);

    var proposal = proposalsMap[_proposal];
    proposal.undoVote(msg.sender);

    votesCount -= 1;

    UndoVoteEvent(proposal, msg.sender);
  }

  event UndoVoteEvent(address indexed proposal, address voter);

}

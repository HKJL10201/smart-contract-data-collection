pragma solidity ^0.4.11;

import "./TokenBallot.sol";
import "./AddressesList.sol";

contract BallotProposal {
  using AddressesList for AddressesList.data;

  mapping (address => address) public votesMap;
  AddressesList.data public votes;
  string public name;
  string public infoUrl;

  TokenBallot public ballot;

  // true when final results are available
  bool public finalized;

  // final results - only valid if finalized is true
  uint256  public finalVoters;
  uint256  public finalVotedTokens;

  // total token supply at finalization time
  uint256  public finalAllVotedTokens;

  modifier onlyBallotCallable() {
    assert(msg.sender == address(ballot));
    _;
  }

  modifier onlyIfNotFinalized() {
    assert(finalized == false);
    _;
  }

  function BallotProposal(string _name, TokenBallot _ballot, string _infoUrl) {
    name = _name;
    ballot = _ballot;
    infoUrl = _infoUrl;
    BallotProposalCreatedEvent(_ballot, _name, _infoUrl);
  }

  event BallotProposalCreatedEvent(address ballot, string name, string infoUrl);

  // only the ballot contract code may initiate a vote for the proposal
  function vote(address voter) external onlyBallotCallable {
    assert (votesMap[voter] == address(0));
    votesMap[voter] = msg.sender;
    votes.append(voter);
    VoteEvent(voter);
  }

  function finalizeResults (
    uint256 _voters,
    uint256 _votedTokens,
    uint256 _allVotedtokens
  ) external onlyBallotCallable onlyIfNotFinalized {
    finalized = true;
    finalVoters = _voters;
    finalVotedTokens = _votedTokens;
    finalAllVotedTokens = _allVotedtokens;

    FinalResultsEvent(_voters, _votedTokens, _allVotedtokens);
  }

  event FinalResultsEvent(uint256 voters, uint256 votedTokens, uint256 votingTokenAll);

  event VoteEvent(address voter);

  // only the ballot contract code may initiate a vote for the proposal
  function undoVote(address voter) external onlyBallotCallable {

    assert (votesMap[voter] != address(0));

    votesMap[voter] = address(0);
    var item = votes.find(voter);
    if (votes.iterate_valid(item))  {
      votes.remove(item);
    }

    UndoVoteEvent(voter);
  }

  event UndoVoteEvent(address vorter);

  // voters iteration methods

  function votersCount() external constant returns (uint80) {
    return votes.itemsCount();
  }

  function getFirstVoterIdx() external constant returns(uint80) {
    if (votes.itemsCount() == 0) throw;
    var it = votes.iterate_start();
    if (votes.iterate_valid(it)) return it;
    else throw;
  }

  function hasNextVoter(uint80 idx) external constant returns (bool) {
    var it = votes.iterate_next(idx);
    return votes.iterate_valid(it);
  }

  function getNextVoterIdx(uint80 idx) external constant returns(uint80) {
    var it = votes.iterate_next(idx);
    if (votes.iterate_valid(it)) return it;
    else throw;
  }

  function getVoterAt(uint80 idx) external constant returns(address) {
    if (votes.iterate_valid(idx)) return votes.iterate_get(idx);
    else return address(0);
  }
}

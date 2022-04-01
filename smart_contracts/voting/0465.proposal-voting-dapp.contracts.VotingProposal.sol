pragma solidity ^0.5.0;

contract VotingProposal {

  // Proposal Structure
  struct Proposal {
    string text;
    uint positiveVotes;
    uint negativeVotes;
  }

  // Defining proposal
  Proposal public proposal;

  // Array of voters key = addresses and values = their Vote
  // values could be a struct of Voter but to keep it simple, we just going to save the vote (1, -1);
  mapping(address => int8) public voters;

  constructor() public {
    proposal = Proposal("This is my first Proposal example", 0, 0);
  }

  modifier canVote {
    require(!hasVoted(), "cannot vote twice");
    _;
  }

  modifier costs(uint _amount) {
    require(msg.value >= _amount, "Insufficient funds to vote");

    _;

    if (msg.value > _amount)
      msg.sender.transfer(msg.value - _amount);
  }

  // Just for debugging purposes
  event LogString(string _str);
  event LogUInt(uint _int);

  event VoteReceived(
    address indexed _from,
    int8 _vote,
    int _totalVotes
  );

  function hasVoted () public view returns (bool) {
    return voters[msg.sender] != 0;
  }

  /*
   * An account cannot vote twice and must send 0.01 ether to be allowed to vote
   */
  function vote(int8 _vote)
    public
    payable
    canVote
    costs(0.01 ether)
  {
    require(_vote == 1 || _vote == -1);
    voters[msg.sender] = _vote;

    if (_vote == 1) {
        proposal.positiveVotes++;
    } else {
        proposal.negativeVotes++;
    }
    emit VoteReceived(msg.sender, _vote, getProposalTotalCount());
  }

  function getVote() public view returns (int8) {
    require(hasVoted(), "Account hasn't voted");
    return voters[msg.sender];
  }

  function getProposalTotalCount() public view returns (int) {
    return int(proposal.positiveVotes - proposal.negativeVotes);
  }

  function getVotersCount() public view returns (uint) {
      return proposal.positiveVotes + proposal.negativeVotes;
  }
}

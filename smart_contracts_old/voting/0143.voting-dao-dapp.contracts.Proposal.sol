// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Voting DAO
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProposalFactory {
  Proposal[] public deployedProposals;

  function createProposal(
    string memory _title,
    string memory _description,
    address[] memory _voters,
    uint256 _durationVotingMinutes
  ) public {
    Proposal newProposal = new Proposal(
      msg.sender,
      _title,
      _description,
      _voters,
      _durationVotingMinutes
    );
    deployedProposals.push(newProposal);
  }

  function getDeployedProposals() public view returns (Proposal[] memory) {
    return deployedProposals;
  }
}

contract VotingToken is ERC20 {
  constructor(uint256 initialSupply) ERC20("VOTING TOKEN", "VTT") {
    _mint(msg.sender, initialSupply);
  }
}

contract Proposal is VotingToken {
  address public manager; // initiator
  string public title;
  string public description;
  uint256 public votingEnd; // UNIX timestamp
  enum Vote { YES, NO } // possible votes
  bool public completed;
  bool public accepted; // final result
  uint256 public approvalsCount;
  uint256 public objectionsCount;
  uint256 public votersCount;
  mapping(address => bool) voters;
  address[] public votersList;

  // events (no index needed)
  event Winner(
    address _contract,
    bool _won,
    uint256 _approvals,
    uint256 _objections
  );

  event VoteDelivery (
    Vote _participantsVote,
    uint _amount
  );

  // modifiers
  modifier isLegitVoter(address voter) {
    require(voters[voter], "Voter is not legitimized.");
    _;
  }

  modifier isNotCompleted() {
    require(!completed, "This proposal is already completed");
    _;
  }

  constructor(
    address _creator,
    string memory _title,
    string memory _description,
    address[] memory _voters,
    uint256 _durationVotingMinutes
  ) VotingToken(_voters.length) {
    manager = _creator;
    title = _title;
    description = _description;
    completed = false;
    votersCount = _voters.length;
    votingEnd = block.timestamp + _durationVotingMinutes * 1 minutes; // timestamp in seconds (since 1.1.1970) of the mined block - attention: set by miner, possible to manipulate (don't use it on mainnet)
    votersList = _voters; // for summary in front-end

    // transfer equal amount of voting rights to voters (addresses)
    for (uint256 i = 0; i < _voters.length; i++) {
      address voter = _voters[i];
      voters[voter] = true; // add voter to mapping - needed for require statements
      transfer(voter, totalSupply() / _voters.length); // transfer voting right (token)
    }
  }

  // for or against proposal
  function vote(Vote _participantsVote, uint256 _amount)
    public
    isLegitVoter(msg.sender)
    isNotCompleted
  {
    // check if voting is still in time window
    require(block.timestamp <= votingEnd, "Time window for voting expired.");

    // YES or NO vote - add to counter
    if (_participantsVote == Vote.YES) {
      approvalsCount = approvalsCount + _amount;
    } else {
      objectionsCount = objectionsCount + _amount;
    }

    // burn vote (token)
    _burn(msg.sender, _amount);

    // emit vote
    emit VoteDelivery(_participantsVote, _amount);
  }

  // give voting rights to additional voters
  function giveVotingRights(address _account)
    public
    isNotCompleted
  {
    // only manager can give additional voting rights
    require(msg.sender == manager);

    // check if voter is not already in our mapping - otherwise more than one vote
    require(!voters[_account]);

    // don't allow sending voting rights to manager
    require(manager != _account);

    // add new voter to voters mapping
    voters[_account] = true;

    // create new voting right (token)
    _mint(_account, 1);
  }

  // transfer voting right to another legitimized voter
  function transfer(address _recipient, uint256 _amount)
    public
    override
    isLegitVoter(_recipient)
    isNotCompleted
    returns (bool)
  {
    // transfer voting right to recipient, which must be in our voters mapping (isLegitVoter)
    _transfer(_msgSender(), _recipient, _amount);

    return true;
  }

  // pick winner
  function pickWinner() public isNotCompleted {
    // check if proposal is not already ended
    require(!completed, "Proposal already ended.");

    // if not all people voted, check for votingEnd
    if (votersCount != approvalsCount + objectionsCount) {
      // check if votingEnd is already reached
      require(
        block.timestamp >= votingEnd,
        "Can't pick winner; voting end not reached yet or not all voters voted."
      );
    }

    // if more votes for yes, emit Winner true
    if (approvalsCount > objectionsCount) {
      accepted = true;
      emit Winner(address(this), true, approvalsCount, objectionsCount);
    } else {
      accepted = false;
      emit Winner(address(this), false, approvalsCount, objectionsCount);
    }

    // mark proposal as completed
    completed = true;
  }

  // just return summary for front-end
  function getSummary()
    public
    view
    returns (
      address,
      string memory,
      string memory,
      uint256,
      bool,
      bool,
      uint256,
      uint256,
      uint256,
      address[] memory
    )
  {
    return (
      manager,
      title,
      description,
      votingEnd,
      completed,
      accepted,
      approvalsCount,
      objectionsCount,
      votersCount,
      votersList
    );
  }
}
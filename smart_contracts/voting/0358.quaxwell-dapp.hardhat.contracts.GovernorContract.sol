// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/**
 * The core contract that contains all the logic and primitives. It is abstract
 * and requires choosing some of the modules below, or custom ones
 */
import "@openzeppelin/contracts/governance/Governor.sol";
// Extracts voting weight from an ERC20Votes token
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
/**
 * Combines with GovernorVotes to set the quorum as a fraction of the total
 * token supply
 */
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
// Simple voting mechanism with 3 voting options: Against, For and Abstain
import "./GovernorCountingSimple.sol";
/**
 * Manages some of the settings (voting delay, initial and minimum voting period
 * duration, and proposal threshold) in a way that can be updated through a
 * governance proposal, without requiring an upgrade
 */
import "./GovernorSettings.sol";

/// Utils
import "@openzeppelin/contracts/utils/Timers.sol";

contract GovernorContract is
  Governor,
  GovernorSettings,
  GovernorCountingSimple,
  GovernorVotes,
  GovernorVotesQuorumFraction
{
  using Timers for Timers.BlockNumber;

  /// @dev Emitted when a vote is casted
  event LogVoteCasted(address voter, uint256 proposalId, uint8 support, uint256 weight);

  address private owner;

  mapping(uint256 => ProposalCore) private _proposals;

  constructor(
    IVotes tokenAddress,
    string memory name_,
    uint256 initialVotingDelay,
    uint256 initialVotingPeriod,
    uint256 initialMinimumVotingPeriod,
    uint256 initialProposalThreshold,
    uint256 quorumNumeratorValue
  )
    Governor(name_)
    GovernorSettings(
      initialVotingDelay,
      initialVotingPeriod,
      initialMinimumVotingPeriod,
      initialProposalThreshold
    )
    GovernorVotes(tokenAddress)
    GovernorVotesQuorumFraction(quorumNumeratorValue)
  // solhint-disable-next-line no-empty-blocks
  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can perform this action");
    _;
  }

  /// @dev Returns votes available for voting in this voting period
  function getAvailableVotingPower() public view returns (uint256) {
    address account = _msgSender();

    if (_currentPeriodVoteStart.isUnset()) {
      return _getVotes(account, block.number - 1, _defaultParams());
    } else {
      uint256 _totalWeight = _getVotes(
        account,
        _currentPeriodVoteStart.getDeadline(),
        _defaultParams()
      );
      return _totalWeight - _castedVotes[_currentPeriodVoteStart.getDeadline()][account];
    }
  }

  /**
   * @dev Casts votes following quadratic voting formula.
   *
   * Emits a {LogVoteCasted} event.
   */
  function vote(uint256 proposalId, uint256 weight, uint8 support) public {
    address account = _msgSender();
    uint256 _totalWeight = _getVotes(
      account,
      _currentPeriodVoteStart.getDeadline(),
      _defaultParams()
    );
    uint256 _quadraticWeight = weight ** 2;

    require(state(proposalId) == ProposalState.Active, "Proposal not active");
    require(
      _castedVotes[_currentPeriodVoteStart.getDeadline()][account] + _quadraticWeight <
        _totalWeight,
      "Exceeded voting power"
    );

    emit LogVoteCasted(msg.sender, proposalId, support, weight);
    _countVote(proposalId, account, support, _quadraticWeight, _defaultParams());
  }

  /**
   * @dev Create a new proposal.
   *
   * Emits a {ProposalCreated} event.
   */
  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  ) public override onlyOwner returns (uint256) {
    require(
      getVotes(_msgSender(), block.number - 1) >= proposalThreshold(),
      "Votes below proposal threshold"
    );

    uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

    require(targets.length == values.length, "Invalid proposal length");
    require(targets.length == calldatas.length, "Invalid proposal length");
    require(targets.length > 0, "Empty proposal");

    ProposalCore storage proposal = _proposals[proposalId];

    require(proposal.voteStart.isUnset(), "Proposal already exists");

    uint64 snapshot = uint64(block.number) + uint64(votingDelay());
    proposal.voteStart.setDeadline(snapshot);

    /**
     * @dev Proposals voting period should end at {_currentPeriodVoteEnd}.
     * If {_currentPeriodVoteEnd} already expired, first proposal of a new
     * voting period should establish a new {_currentPeriodVoteEnd}.
     */
    uint64 deadline;
    if (_currentPeriodVoteEnd.isStarted() && !_currentPeriodVoteEnd.isExpired()) {
      deadline = _currentPeriodVoteEnd.getDeadline();

      require(deadline - block.number > minimumVotingPeriod(), "Voting period should be longer");

      proposal.voteEnd.setDeadline(deadline);
    } else {
      deadline = snapshot + uint64(votingPeriod());
      proposal.voteEnd.setDeadline(deadline);
      _currentPeriodVoteEnd.setDeadline(deadline);
      /// @dev {_currentPeriodVoteStart} would be taken into account as
      /// so to extract voting weight from token
      _currentPeriodVoteStart.setDeadline(snapshot);
    }

    emit ProposalCreated(
      proposalId,
      _msgSender(),
      targets,
      values,
      new string[](targets.length),
      calldatas,
      snapshot,
      deadline,
      description
    );

    return proposalId;
  }

  /// @dev See {IGovernor-execute}.
  function execute(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) public payable override returns (uint256) {
    uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

    ProposalState status = state(proposalId);
    require(
      status == ProposalState.Succeeded || status == ProposalState.Queued,
      "Proposal not successful"
    );
    _proposals[proposalId].executed = true;

    emit ProposalExecuted(proposalId);

    _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
    _execute(proposalId, targets, values, calldatas, descriptionHash);
    _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

    return proposalId;
  }

  /// @dev See {IGovernor-state}.
  function state(uint256 proposalId) public view override returns (ProposalState) {
    ProposalCore storage proposal = _proposals[proposalId];

    if (proposal.executed) {
      return ProposalState.Executed;
    }

    if (proposal.canceled) {
      return ProposalState.Canceled;
    }

    uint256 snapshot = proposalSnapshot(proposalId);

    if (snapshot == 0) {
      revert("Governor: unknown proposal id");
    }

    if (snapshot >= block.number) {
      return ProposalState.Pending;
    }

    uint256 deadline = proposalDeadline(proposalId);

    if (deadline >= block.number) {
      return ProposalState.Active;
    }

    if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
      return ProposalState.Succeeded;
    } else {
      return ProposalState.Defeated;
    }
  }

  /// @dev See {IGovernor-proposalSnapshot}.
  function proposalSnapshot(uint256 proposalId) public view override returns (uint256) {
    return _proposals[proposalId].voteStart.getDeadline();
  }

  /// @dev See {IGovernor-proposalDeadline}.
  function proposalDeadline(uint256 proposalId) public view override returns (uint256) {
    return _proposals[proposalId].voteEnd.getDeadline();
  }

  /// @dev See {GovernorSettings-proposalThreshold}.
  function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
    return GovernorSettings.proposalThreshold();
  }

  /// @dev Override and disable this function
  function castVote(uint256, uint8) public pure override returns (uint256) {
    // solhint-disable-next-line reason-string
    revert();
  }

  /// @dev Override and disable this function
  function castVoteWithReason(
    uint256,
    uint8,
    string memory
  ) public pure override returns (uint256) {
    // solhint-disable-next-line reason-string
    revert();
  }

  /// @dev Override and disable this function
  function castVoteWithReasonAndParams(
    uint256,
    uint8,
    string calldata,
    bytes memory
  ) public pure override returns (uint256) {
    // solhint-disable-next-line reason-string
    revert();
  }

  /// @dev Override and disable this function
  function castVoteBySig(
    uint256,
    uint8,
    uint8,
    bytes32,
    bytes32
  ) public pure override returns (uint256) {
    // solhint-disable-next-line reason-string
    revert();
  }

  /// @dev Override and disable this function
  function castVoteWithReasonAndParamsBySig(
    uint256,
    uint8,
    string calldata,
    bytes memory,
    uint8,
    bytes32,
    bytes32
  ) public pure override returns (uint256) {
    // solhint-disable-next-line reason-string
    revert();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

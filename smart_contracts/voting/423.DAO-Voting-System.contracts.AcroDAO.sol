//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./NftMarketplace.sol";

contract AcroDAO {
  // enumerations
  enum ProposalState {
    Active,
    Succesful,
    Executed,
    Cancelled,
    Expired
  }

  enum Support {
    AGAINST,
    FOR,
    ABSTAIN
  }

  // struct
  struct Receipt {
    bool hasVoted;
    uint8 support;
  }

  struct ProposalVote {
    uint256 againstVotes;
    uint256 forVotes;
    uint256 abstainVotes;
  }

  struct Proposal {
    uint256 propId;
    address proposer;
    address payable[] targets;
    uint256[] values;
    string[] signature;
    bytes[] calldatas;
    uint256 startTime;
    uint256 endTime;
    ProposalVote votes;
    ProposalState state;
    mapping(address => Receipt) receipts;
  }

  // modifiers
  modifier membersOnly() {
    require(isMember[msg.sender], "members only");
    _;
  }

  modifier govenorOnly() {
    require(msg.sender == govenor, "govenor only");
    _;
  }

  // events
  event CastVote(address voter, uint256 proposalId, uint8 support);
  event ProposalCreate(
    uint256 proposalId,
    address proposer,
    address payable[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startTime,
    uint256 endTime,
    string description
  );

  // state variables
  bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
  bytes32 private constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
  string public constant name = "DAO Governor";
  address public govenor;
  uint256 public constant QUORUM = 25;
  uint256 public constant DURATION = 7 days;
  address[] public members;

  // mappings
  mapping(uint256 => Proposal) public proposals;
  mapping(address => bool) public isMember;
  mapping(address => uint256) public latestId;

  // constructor
  constructor() {
    govenor = msg.sender;
  }

  // functions
  function quorumReached(uint256 proposalId) public view returns (bool) {
    Proposal storage proposal = proposals[proposalId];
    uint256 quorumVotesCount = (QUORUM * members.length) / 100;
    if (proposal.votes.forVotes + proposal.votes.againstVotes >= quorumVotesCount) {
      return true;
    }
    return false;
  }

  function voteSucceed(uint256 proposalId) public view returns (bool) {
    Proposal storage proposal = proposals[proposalId];
    if (proposal.votes.forVotes > proposal.votes.againstVotes) {
      return true;
    } else {
      return false;
    }
  }

  function getMembership() external payable {
    require(!isMember[msg.sender], "already member");
    require(msg.value == 1 ether, "should 1 ether");
    isMember[msg.sender] = true;
    members.push(msg.sender);
  }

  function returnMembership(address _member) external view returns (bool) {
    return isMember[_member];
  }

  function returnProposalState(uint256 proposalId) public view returns (ProposalState) {
    Proposal storage proposal = proposals[proposalId];
    if (proposal.endTime < block.timestamp && quorumReached(proposalId) && voteSucceed(proposalId)) {
      return ProposalState.Succesful;
    } else if (proposal.state == ProposalState.Cancelled) {
      return ProposalState.Cancelled;
    } else if (proposal.state == ProposalState.Executed) {
      return ProposalState.Executed;
    } else if (proposal.endTime < block.timestamp && !voteSucceed(proposalId)) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Active;
    }
  }

  function hashProposal(
    address payable[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    bytes32 _description
  ) internal pure virtual returns (uint256) {
    return uint256(keccak256(abi.encode(_targets, _values, _calldatas, _description)));
  }

  // create proposal
  function propose(
    address payable[] memory _targets,
    uint256[] memory _values,
    string[] memory _signature,
    bytes[] memory _calldatas,
    string memory _description
  ) external membersOnly virtual returns (uint256) {
    uint256 proposalId = hashProposal(_targets, _values, _calldatas, keccak256(bytes(_description)));
    require(_targets.length == _values.length, "invalid values length");
    require(_targets.length == _calldatas.length, "invalid calldata length");
    require(_targets.length > 0, "empty proposal");
    Proposal storage proposal = proposals[proposalId];
    require(proposal.startTime == 0, "already exist");

    latestId[msg.sender] = proposalId;
  
    proposal.propId = proposalId;
    proposal.proposer = msg.sender;
    proposal.targets = _targets;
    proposal.values = _values;
    proposal.signature = _signature;
    proposal.calldatas = _calldatas;
    proposal.startTime = block.timestamp;
    proposal.endTime = block.timestamp + DURATION;

    emit ProposalCreate(
      proposalId,
      msg.sender,
      _targets,
      _values,
      _signature,
      _calldatas,
      block.timestamp,
      block.timestamp + DURATION,
      _description
    );

    return proposalId;
  }

  function returnVotes(uint256 proposalId) external view returns (
    uint256 againstVotes,
    uint256 forVotes,
    uint256 abstainVotes
  ) {
    Proposal storage proposal = proposals[proposalId];
    ProposalVote storage votes = proposal.votes;
    return (votes.againstVotes, votes.forVotes, votes.abstainVotes);
  }

  function _execute(
    address _target,
    uint256 _value,
    string memory _signature,
    bytes memory _data
    ) internal returns (bool success, bytes memory data) {
      bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _data);
      return _target.call{ value: _value }(callData);
  }

  // execute the queued project
  function executeProposal(uint256 proposalId) external {
    require(returnProposalState(proposalId) == ProposalState.Succesful, "must successful");
    Proposal storage proposal = proposals[proposalId];
    proposal.state = ProposalState.Executed;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      (bool success, ) = _execute(
        proposal.targets[i],
        proposal.values[i],
        proposal.signature[i],
        proposal.calldatas[i]
      );
      require(success, "execution failed");
    }
  }

  // govenor can cancel the unsuccessful project
  function cancelProposal(uint256 proposalId) external govenorOnly {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.state != ProposalState.Executed, "already executed");
    proposal.state = ProposalState.Cancelled;
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }

  // cast vote with signature
  function castVote(
    uint256 proposalId,
    uint8 support,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.state == ProposalState.Active, "not active");
    bytes32 separator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", separator, structHash));
    address signer = ecrecover(digest, _v, _r, _s);
    require(signer != address(0), "invalid signature");
    require(isMember[signer], "not a member");
    Receipt storage receipt = proposal.receipts[signer];
    require(!receipt.hasVoted, "already voted");
    if (support == uint8(Support.AGAINST)) {
      proposal.votes.againstVotes++;
    } else if (support == uint8(Support.FOR)) {
      proposal.votes.forVotes++;
    } else if (support == uint8(Support.ABSTAIN)) {
      proposal.votes.abstainVotes++;
    }
    receipt.hasVoted = true;
    receipt.support = support;
    emit CastVote(signer, proposalId, support);
  }
}

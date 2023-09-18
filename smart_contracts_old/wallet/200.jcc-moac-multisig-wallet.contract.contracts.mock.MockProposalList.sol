pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "../utils/Proposal.sol";
import "../utils/ProposalList.sol";

contract MockProposalList {
  using ProposalList for ProposalList.proposalMap;

  ProposalList.proposalMap _proposals;

  function insertTopic(
    uint topicId,
    uint timestamp,
    uint endtime,
    uint voteType,
    uint origin,
    uint value,
    address target)
  public returns (bool) {
    return _proposals.insertTopic(topicId, timestamp, endtime, voteType, origin, value, target, msg.sender);
  }

  function getVotingCount() public view returns (uint) {
    return _proposals.getVotingCount();
  }

  function getVotedCount() public view returns (uint) {
    return _proposals.getVotedCount();
  }

  function getAllVotingTopicIds() public view returns (uint[]) {
    return _proposals.getAllVotingTopicIds();
  }

  function getTopic(uint topicId) public view returns (Proposal.topic) {
    return _proposals.getTopic(topicId);
  }

  function voteTopic(uint topicId, uint timestamp, bool confirm) public returns (bool) {
    return _proposals.voteTopic(topicId, timestamp, msg.sender, confirm);
  }

  function getDetailIdxs(uint topicId) public view returns (bytes32[]) {
    return _proposals.getDetailIdxs(topicId);
  }

  function getVoteDetail(uint topicId) public view returns (Proposal.voteDetail) {
    bytes32 key = keccak256(abi.encodePacked(topicId, msg.sender));
    return _proposals.getVoteDetail(key);
  }

  function getVoteDetailsByTopic(uint topicId) public view returns (Proposal.voteDetail[]) {
    return _proposals.getVoteDetailsByTopic(topicId);
  }

  function moveTopic(uint topicId) public returns (bool) {
    return _proposals.moveTopic(topicId);
  }

  function getMyVotedTopicIds(address sponsor, uint from, uint to) public view returns (uint[] memory) {
    return _proposals.getMyVotedTopicIds(sponsor, from, to);
  }

  function getVotedTopicIds(uint from, uint to) public view returns (uint[] memory) {
    return _proposals.getVotedTopicIds(from, to);
  }
}

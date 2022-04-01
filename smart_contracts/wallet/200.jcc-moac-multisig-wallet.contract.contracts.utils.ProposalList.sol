pragma solidity 0.4.24;
import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "./Proposal.sol";

/**
 * @dev 提案列表管理模块.
 */
library ProposalList {
  using SafeMath for uint256;

  /**
    提案状态列表
   */
  struct stateList {
    uint[] voting;
    uint[] voted;
  }

  /**
  所有提案列表
   */
  struct proposalMap
  {
    // 所有提案列表: topic ID是关键字
    mapping(uint => Proposal.topic) _topics;

    // 提案状态
    stateList _voteList;

    // 提案者相关提案列表
    mapping(address => stateList) _sponsors;

    // 所有提案投票记录
    mapping(bytes32 => Proposal.voteDetail) _voteDetails;
    // 按照提案ID的投票明细
    mapping(uint => bytes32[]) _detailIdx;
  }

  function exist(proposalMap storage self,uint topicId) internal view returns (bool) {
    if(self._topics[topicId].topicId == 0) return false;
    return (self._topics[topicId].topicId == topicId);
  }

  // 建立投票议题
  function insertTopic(
    proposalMap storage self,
    uint topicId,
    uint timestamp,
    uint endtime,
    uint voteType,
    uint origin,
    uint value,
    address target,
    address sponsor)
  internal returns (bool){

    require(endtime > timestamp, "end time must bigger than timestamp");
    if (exist(self, topicId)) {
      return false;
    }

    self._topics[topicId].topicId = topicId;
    self._topics[topicId].timestamp = timestamp;
    self._topics[topicId].endtime = endtime;
    self._topics[topicId].voteType = voteType;
    self._topics[topicId].origin = origin;
    self._topics[topicId].value = value;
    self._topics[topicId].target = target;
    self._topics[topicId].sponsor = sponsor;
    self._topics[topicId].yesCount = 0;
    self._topics[topicId].noCount = 0;
    self._topics[topicId].flag = false;
    self._topics[topicId].idx = self._voteList.voting.push(topicId).sub(1);

    // 建立提案发起者关联数据
    self._sponsors[sponsor].voting.push(topicId);

    return true;
  }

  function getVotingCount(proposalMap storage self) internal view returns (uint) {
    return self._voteList.voting.length;
  }
  function getVotedCount(proposalMap storage self) internal view returns (uint) {
    return self._voteList.voted.length;
  }

  function getVotingCountBySponsor(proposalMap storage self, address sponsor) internal view returns (uint) {
    return self._sponsors[sponsor].voting.length;
  }
  function getVotedCountBySponsor(proposalMap storage self, address sponsor) internal view returns (uint) {
    return self._sponsors[sponsor].voted.length;
  }

  // 获得当前未决投票清单，考虑到未决的投票数量有限，因此直接返回所有
  function getAllVotingTopicIds(proposalMap storage self) internal view returns (uint[]) {
    return self._voteList.voting;
  }
  function getAllMyVotingTopicIds(proposalMap storage self, address sponsor) internal view returns (uint[]) {
    return self._sponsors[sponsor].voting;
  }
  function getTopic(proposalMap storage self, uint topicId) internal view returns (Proposal.topic) {
    return self._topics[topicId];
  }

  // 获得当前已决提案id，考虑到数量不断增长，因此采用范围获取
  function getVotedTopicIds(proposalMap storage self, uint from, uint to) internal view returns (uint[] memory) {
    require(to >= from, "index to must bigger than from");
    require(to < self._voteList.voted.length, "index to must smaller than voted count");

    uint len = 0;
    uint size = to.sub(from).add(1);
    //BUG:无法创建一个memory的一个成员的数组？
    uint[] memory res = new uint[](size >= 2 ? size:2);
    for (uint i = from; i <= to; i++) {
      res[len] = self._voteList.voted[i];
      len = len.add(1);
    }
    return res;
  }

  function getMyVotedTopicIds(proposalMap storage self, address sponsor, uint from, uint to) internal view returns (uint[] memory) {
    require(to >= from, "index to must bigger than from");
    require(to < self._sponsors[sponsor].voted.length, "index to must smaller than voted count");

    uint len = 0;
    uint size = to.sub(from).add(1);
    //BUG:无法创建一个memory的一个成员的数组？
    uint[] memory res = new uint[](size >= 2 ? size:2);
    for (uint i = from; i <= to; i++) {
      res[len] = self._sponsors[sponsor].voted[i];
      len = len.add(1);
    }
    return res;
  }

  // 将待决议题移动到已决议题中
  function moveTopic(proposalMap storage self, uint topicId) internal returns (bool) {
    if (!exist(self, topicId)) {
      return false;
    }
    // 已经被标记为完成的不再处理
    if (self._topics[topicId].flag) {
      return false;
    }

    // 修改全局的议题状态
    uint row2Del = self._topics[topicId].idx;
    uint key2Move = self._voteList.voting[self._voteList.voting.length.sub(1)];
    self._voteList.voting[row2Del] = key2Move;
    self._topics[key2Move].idx = row2Del;
    self._voteList.voting.length = self._voteList.voting.length.sub(1);

    // 修改提案者的议题状态
    for (uint i = 0; i < self._sponsors[self._topics[topicId].sponsor].voting.length; i++) {
      if (self._sponsors[self._topics[topicId].sponsor].voting[i] == topicId) {
        self._sponsors[self._topics[topicId].sponsor].voted.push(topicId);
        self._sponsors[self._topics[topicId].sponsor].voting[i] = self._sponsors[self._topics[topicId].sponsor].voting[self._sponsors[self._topics[topicId].sponsor].voting.length.sub(1)];
        self._sponsors[self._topics[topicId].sponsor].voting.length = self._sponsors[self._topics[topicId].sponsor].voting.length.sub(1);
        break;
      }
    }

    // 设置议题结束 移动到已决议题索引中
    self._topics[topicId].flag = true;
    self._topics[topicId].idx = self._voteList.voted.push(topicId).sub(1);

    return true;
  }

  function existVote(proposalMap storage self,bytes32 key) internal view returns (bool) {
    if(self._voteDetails[key].topicId == 0) return false;
    return (key == keccak256(abi.encodePacked(self._voteDetails[key].topicId, self._voteDetails[key].voter)));
  }

  // 处理投票明细信息
  function voteTopic(
    proposalMap storage self,
    uint topicId,
    uint timestamp,
    address voter,
    bool confirm)
  internal returns (bool) {
    if (!exist(self, topicId)) {
      return false;
    }

    // 投过票不能再投了
    bytes32 key = keccak256(abi.encodePacked(topicId, voter));
    if (existVote(self, key)) {
      return false;
    }

    self._voteDetails[key].topicId = topicId;
    self._voteDetails[key].timestamp = timestamp;
    self._voteDetails[key].voter = voter;
    self._voteDetails[key].flag = confirm;
    self._voteDetails[key].idx = self._detailIdx[topicId].push(key).sub(1);

    if (confirm) {
      self._topics[topicId].yesCount = self._topics[topicId].yesCount.add(1);
    } else {
      self._topics[topicId].noCount = self._topics[topicId].noCount.add(1);
    }
    return true;
  }

  function processTopic(proposalMap storage self, uint topicId, uint percent, uint voters) internal returns (bool) {
    if (!exist(self, topicId)) {
      return false;
    }

    self._topics[topicId].percent = percent;
    self._topics[topicId].voters = voters;

    return true;
  }

  function getDetailIdxs(proposalMap storage self, uint topicId) internal view returns (bytes32[]) {
    return self._detailIdx[topicId];
  }
  // 前端的钱包想知道自己对议题有无投票，可以用topicId，钱包地址做一次keccak256运算得到key，检索是否有数据
  function getVoteDetail(proposalMap storage self, bytes32 key) internal view returns (Proposal.voteDetail) {
    return self._voteDetails[key];
  }
  function getVoteDetailsByTopic(proposalMap storage self, uint topicId) internal view returns (Proposal.voteDetail[] memory) {
    uint len = self._detailIdx[topicId].length;

    require(len > 0, "must have vote detail");

    Proposal.voteDetail[] memory res = new Proposal.voteDetail[](len);

    bytes32 key;
    for (uint i = 0; i < len; i++) {
      key = self._detailIdx[topicId][i];
      res[i] = self._voteDetails[key];
    }
    return res;
  }

  // 检查某种类型或者某个用户是否发起过提案
  function votingExist(proposalMap storage self, uint voteType, address sponsor) internal view returns (bool) {
    bool noCheckSponsor = (address(0) == sponsor);

    if (noCheckSponsor) {
      return votingExistType(self, voteType);
    }

    return votingExistTypeBySponsor(self, voteType, sponsor);
  }
  // 只检查有无相同类型提案
  function votingExistType(proposalMap storage self, uint voteType) internal view returns (bool) {
    if (self._voteList.voting.length == 0) {
      return false;
    }
    for (uint i = 0; i < self._voteList.voting.length; i++) {
      Proposal.topic storage t = self._topics[self._voteList.voting[i]];
      if (t.voteType != voteType) {
        continue;
      }
      return true;
    }
    return false;
  }
  // 检查某个用户有无特定类型的提案
  function votingExistTypeBySponsor(proposalMap storage self, uint voteType, address sponsor) internal view returns (bool) {
    if (self._sponsors[sponsor].voting.length == 0) {
      return false;
    }
    for (uint i = 0; i < self._sponsors[sponsor].voting.length; i++) {
      Proposal.topic storage t = self._topics[self._sponsors[sponsor].voting[i]];
      if (t.voteType != voteType) {
        continue;
      }
      return true;
    }
    return false;
  }
}
pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "jcc-solidity-utils/contracts/owner/Administrative.sol";
import "jcc-solidity-utils/contracts/utils/AddressUtils.sol";
import "jcc-solidity-utils/contracts/list/AddressList.sol";
import "jcc-solidity-utils/contracts/list/BalanceList.sol";
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarm.sol";
import "jcc-solidity-utils/contracts/interface/IJccMoacAlarmCallback.sol";
import "./utils/Proposal.sol";
import "./utils/ProposalList.sol";

/**
墨客锁仓多签名钱包
1. 支持充值锁仓
2. 支持设置M-N投票规则
3. 支持第一次初始设置投票人和和投票百分比规则设定
4. 支持通过投票方式决定M-N规则设定
5. 支持通过投票方式增加投票人
6. 支持锁仓人自己发起提币数量的提案，供投票人投票
7. 提供待决已决提案的查询
8. 提供投票，锁仓相关消息的查询
9. 支持投票人多选投票，降低工作强度
 */
contract JccMoacMultiSig is Administrative, IJccMoacAlarmCallback {
  using SafeMath for uint256;
  using AddressUtils for address;

  using AddressList for AddressList.addressMap;
  using ProposalList for ProposalList.proposalMap;
  using BalanceList for BalanceList.balanceMap;

  /**
  投票类型常量定义
   */
  // 配置变动:投票人数
  uint constant TYPE_CONFIG_COUNT = 1;
  // 配置变动:投票通过百分比
  uint constant TYPE_CONFIG_PERCENT = 2;
  // 提现
  uint constant TYPE_WITHDRAW = 3;
  // 选举投票人
  uint constant TYPE_VOTE = 4;
  // 罢免投票人
  uint constant TYPE_RECALL = 5;

  /**
  参与投票的用户
   */
  AddressList.addressMap private _voters;

  /**
  锁仓用户余额和提现金额
   */
  BalanceList.balanceMap private _balanceOfDeposit;
  BalanceList.balanceMap private _balanceOfWithdraw;

  // 当前提案数据及投票数据
  ProposalList.proposalMap _proposals;

  /**
  投票M-N规则,最大投票人数以及通过决议的百分比
   */
  uint private _voterCount;
  uint private _percent;

  /**
  管理员只有一次设置机会
   */
  bool private _onlyonce;
  /**
  停止接受锁仓资金
   */
  bool private _stopDeposit;

  // hundred million of moac, max deposit and withdraw
  uint constant MAX_VALUE = 100000000 * 10**18;

  constructor() Administrative() public {
    _onlyonce = true;
    _stopDeposit = false;
    _voterCount = 3;
    _percent = 50;
  }

  function configureOnce(uint count, uint percent, address[] memory voters)
  public onlyAdministrator
  {
    require(_onlyonce, "admin only configure once");
    require(count >= 3, "voter count must bigger than 3");
    require(percent >= 50, "percent must bigger than 50");
    require(voters.length == count, "voters count is not equal parameter count");

    _voterCount = count;
    _percent = percent;

    uint i;
    for (i = 0; i < _voterCount; i++) {
      _voters.insert(voters[i]);
    }

    _onlyonce = false;
  }
  // 设置接受锁仓标识
  function setStopDeposit(bool flag) public onlyAdministrator
  {
    _stopDeposit = flag;
  }
  function getStopDeposit() public view returns (bool)
  {
    return _stopDeposit;
  }

  function getPercent() public view returns (uint) {
    return _percent;
  }

  function getVoters() public view returns (address[]) {
    return _voters.getList(0, _voters.count());
  }

  function isVoter(address addr) public view returns (bool) {
    return _voters.exist(addr);
  }
  event CreateProposal(uint indexed topicId, uint indexed voteType, uint indexed value, address target);

  // 发起变更投票人数百分比配置的提案,只有投票人才能发起这个提议
  function createPercentProposal(uint topicId, uint timestamp, uint endtime, uint percent) public returns (bool) {
    require(!_onlyonce, "admin does not configure yet");
    require(percent >= 50 && percent <= 100, "voter percent must bigger than 50");
    require(percent != _percent, "must be different");
    require(_voters.exist(msg.sender), "only voter can commit config change");

    // 一次只能一个修改投票百分比的提案
    bool exist = _proposals.votingExist(TYPE_CONFIG_PERCENT, address(0));
    require(!exist, "only percent proposal in voting.");

    if (_proposals.insertTopic(topicId, timestamp, endtime, TYPE_CONFIG_PERCENT, _percent, percent, address(0), msg.sender)) {
      emit CreateProposal(topicId, TYPE_CONFIG_PERCENT, percent, address(0));
      return true;
    }
    return false;
  }

  // 发起选举投票人提案,任何非投票人能发起这个提议
  function createVoterProposal(uint topicId, uint timestamp, uint endtime, address target) public returns (bool) {
    require(!_onlyonce, "admin does not configure yet");
    require(!_voters.exist(target), "can not vote exist voter");

    // 一个人只能发起一个投票人提案
    bool exist = _proposals.votingExist(TYPE_VOTE, msg.sender);
    require(!exist, "only one voter proposal per user in voting.");

    if (_proposals.insertTopic(topicId, timestamp, endtime, TYPE_VOTE, 0, 0, target, msg.sender)) {
      emit CreateProposal(topicId, TYPE_VOTE, 0, target);
      return true;
    }
    return false;
  }

  // 发起罢免投票人提案,只有投票人才能发起这个提议
  function createRecallProposal(uint topicId, uint timestamp, uint endtime, address target) public returns (bool) {
    require(!_onlyonce, "admin does not configure yet");
    require(_voters.count() >= 3, "at least 3 voter");
    require(_voters.exist(target), "must recall exist voter");
    require(_voters.exist(msg.sender), "only voter can commit");

    // 一个人只能发起一个罢免投票人提案
    bool exist = _proposals.votingExist(TYPE_RECALL, msg.sender);
    require(!exist, "only one recall proposal per user in voting.");

    if (_proposals.insertTopic(topicId, timestamp, endtime, TYPE_RECALL, 0, 0, target, msg.sender)) {
      emit CreateProposal(topicId, TYPE_RECALL, 0, target);
      return true;
    }
    return false;
  }

  // 发起提现提案,只有充值人才能发起这个提议
  function createWithdrawProposal(uint topicId, uint timestamp, uint endtime, uint amount) public returns (bool) {
    require(!_onlyonce, "admin does not configure yet");
    require(_stopDeposit, "only withdraw after set stop deposit flag");

    bool exist = _proposals.votingExist(TYPE_WITHDRAW, msg.sender);
    require(!exist, "only one withdraw proposal per user in voting.");

    uint _bd = _balanceOfDeposit.balance(msg.sender);
    uint _bw = _balanceOfWithdraw.balance(msg.sender);
    uint _amount = _bd.sub(_bw);

    // 发起提现提案的人必须有足够的提现资金,没有存款的人余额是0，无权发起提案
    require(_amount > 0 && _amount >= amount, "sender must have enough money");

    if (_proposals.insertTopic(topicId, timestamp, endtime, TYPE_WITHDRAW, 0, amount, msg.sender, msg.sender)) {
      emit CreateProposal(topicId, TYPE_WITHDRAW, amount, msg.sender);
      return true;
    }
    return false;
  }

  function getVotingCount() public view returns (uint) {
    return _proposals.getVotingCount();
  }

  function getVotedCount() public view returns (uint) {
    return _proposals.getVotedCount();
  }

  function getMyVotingCount() public view returns (uint) {
    return _proposals.getVotingCountBySponsor(msg.sender);
  }

  function getMyVotedCount() public view returns (uint) {
    return _proposals.getVotedCountBySponsor(msg.sender);
  }

  function getAllVotingTopicIds() public view returns (uint[]) {
    return _proposals.getAllVotingTopicIds();
  }

  function getAllMyVotingTopicIds() public view returns (uint[]) {
    return _proposals.getAllMyVotingTopicIds(msg.sender);
  }

  function getVotedTopicIds(uint from, uint to) public view returns (uint[] memory) {
    return _proposals.getVotedTopicIds(from, to);
  }

  function getMyVotedTopicIds(uint from, uint to) public view returns (uint[] memory) {
    return _proposals.getMyVotedTopicIds(msg.sender, from, to);
  }

  function getTopic(uint topicId) public view returns (Proposal.topic) {
    return _proposals.getTopic(topicId);
  }

  event Vote(uint indexed topicId, uint indexed timestamp, bool indexed confirm);
  // 对提案进行投票
  function voteTopic(uint topicId, uint timestamp, bool confirm) public returns (bool) {
    require(!_onlyonce, "admin does not configure yet");
    require(_voters.exist(msg.sender), "only voter can commit");

    if (_proposals.voteTopic(topicId, timestamp, msg.sender, confirm)) {
      emit Vote(topicId, timestamp, confirm);
      return true;
    }

    return false;
  }

  // 对提案进行批量投票
  function batchVoteTopic(uint[] topicIds, uint timestamp, bool confirm) public returns (bool) {
    require(topicIds.length > 0, "topicids length must bigger than 0");

    for (uint i = 0; i < topicIds.length; i++) {
      if (!voteTopic(topicIds[i], timestamp, confirm)) {
        return false;
      }
    }

    return true;
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

  // 计算生效的最少票数
  function getLeastVoterCount() internal view returns(uint) {
    uint _base = _voters.count().mul(_percent);
    uint _count = _base.div(100);

    _count = _base.div(100).mul(100) == _base ? _count : _count.add(1);

    // 不能超过总投票人数
    _count = _count > _voters.count() ? _voters.count() : _count;

    return _count;
  }

  // 扫描是否有到期的提案,关闭提案应该是用时间和投票数据判断，所以对执行的钱包没有要求
  function haveExpire(uint endtime) public view returns(Proposal.topic[], uint) {
    // 扫描所有待决提案，检查是否过期，是否按照表决规则可以关闭，将符合要求的返回
    require(_voters.count() >= 3, "must have voter");
    uint[] memory _voting = _proposals.getAllVotingTopicIds();
    require(_voting.length > 0, "must have voting data");

    Proposal.topic[] memory ret = new Proposal.topic[](_voting.length);
    uint len = 0;
    for (uint i = 0; i < _voting.length; i++) {
      Proposal.topic memory t = _proposals.getTopic(_voting[i]);
      // 提案已经超时
      if (t.endtime <= endtime && block.timestamp >= endtime.div(1000)) {
        ret[len] = t;
        len = len.add(1);
        continue;
      }

      // 当前投票状态是否可以形成决议
      uint _baseCount = getLeastVoterCount();

      if (t.yesCount >= _baseCount || t.noCount >= _baseCount) {
        ret[len] = t;
        len = len.add(1);
      }
    }

    return (ret, len);
  }

  event CloseProposal(uint indexed topicId, uint indexed yesCount, uint indexed totalCount);

  function processMoveTopic(Proposal.topic memory t) internal returns (bool) {
    require(_proposals.moveTopic(t.topicId), "must move to voted successful");

    emit CloseProposal(t.topicId, t.yesCount, _voters.count());
    return true;
  }

  function processPercentExpire(uint topicId) internal returns (bool) {
    Proposal.topic memory t = _proposals.getTopic(topicId);

    uint _baseCount = getLeastVoterCount();

    _proposals.processTopic(topicId, _percent, _voters.count());
    if (t.yesCount >= _baseCount && t.yesCount > t.noCount) {
      _percent = t.value;
    }

    processMoveTopic(t);

    return true;
  }

  function processVoteExpire(uint topicId) internal returns (bool) {
    Proposal.topic memory t = _proposals.getTopic(topicId);

    uint _baseCount = getLeastVoterCount();

    _proposals.processTopic(topicId, _percent, _voters.count());
    if (t.yesCount >= _baseCount && t.yesCount > t.noCount) {
      _voters.insert(t.target);
    }

    processMoveTopic(t);

    return true;
  }

  function processRecallExpire(uint topicId) internal returns (bool) {
    // 发起投票时人数是够的，形成决议后有可能人数降低到3个以下，必须驳回
    require(_voters.count() > 3, "at least 3 voter");
    Proposal.topic memory t = _proposals.getTopic(topicId);

    uint _baseCount = getLeastVoterCount();

    _proposals.processTopic(topicId, _percent, _voters.count());
    if (t.yesCount >= _baseCount && t.yesCount > t.noCount) {
      _voters.remove(t.target);
    }

    processMoveTopic(t);

    return true;
  }

  event Withdraw(address indexed user, uint indexed amount, uint totalWithdraw, uint indexed left);

  function withdraw(Proposal.topic memory t) internal {
    uint _bd = _balanceOfDeposit.balance(t.target);
    uint _bw = _balanceOfWithdraw.balance(t.target);
    uint _amount = _bd.sub(_bw);

    // 发起提现提案的人必须有足够的提现资金,没有存款的人余额是0，无权发起提案
    require(_amount > 0 && _amount >= t.value, "user must have enough money");

    uint all = address(this).balance;
    require(all >= t.value, "contract must have enough money");

    uint totalWithdraw = _balanceOfWithdraw.add(t.target, t.value);
    emit Withdraw(t.target, t.value, totalWithdraw, _bd.sub(totalWithdraw));

    t.target.transfer(t.value);
  }

  function processWithdrawExpire(uint topicId) internal returns (bool) {
    Proposal.topic memory t = _proposals.getTopic(topicId);

    uint _baseCount = getLeastVoterCount();

    _proposals.processTopic(topicId, _percent, _voters.count());
    if (t.yesCount >= _baseCount && t.yesCount > t.noCount) {
      // 执行转账
      withdraw(t);
    }

    processMoveTopic(t);

    return true;
  }

  function process(Proposal.topic t) internal {
    // 投票规则百分比设置
    if (t.voteType == TYPE_CONFIG_PERCENT) {
      processPercentExpire(t.topicId);
    }else if (t.voteType == TYPE_VOTE) {
      // 提名投票人设置
      processVoteExpire(t.topicId);
    }else if (t.voteType == TYPE_RECALL) {
      // 罢免投票设置
      processRecallExpire(t.topicId);
    }else if (t.voteType == TYPE_WITHDRAW) {
      // 提现设置
      processWithdrawExpire(t.topicId);
    }
  }

  function processExpire(uint endtime) public returns (bool) {
    require(!_onlyonce, "admin does not configure yet");
    // 扫描所有待决提案，检查是否过期，是否按照表决规则可以关闭，将符合要求的返回
    require(_voters.count() >= 3, "must have voter");
    uint[] memory _voting = _proposals.getAllVotingTopicIds();
    if (_voting.length == 0) {
      return false;
    }

    uint len = 0;
    for (uint i = 0; i < _voting.length; i++) {
      // 限定每次处理10个，因为可能会有很多提案，导致gas超过打包的要求
      // 清理时投票统计依赖投票时统计不再复核，一个是投票时限制用户反复投票确保统计简单正确
      // 其次是关闭投票时，降低gas开销，如果投票人很多的话，gas可能太多，导致无法关闭
      if (len > 10) {
        break;
      }
      Proposal.topic memory t = _proposals.getTopic(_voting[i]);

      // 提案已经超时
      if (t.endtime <= endtime && block.timestamp >= endtime.div(1000)) {
        process(t);
        len = len.add(1);
        continue;
      }

      // 当前投票状态是否可以形成决议
      uint _baseCount = getLeastVoterCount();

      if (t.yesCount >= _baseCount || t.noCount >= _baseCount) {
        process(t);
        len = len.add(1);
      }
    }

    return true;
  }

  // 接受预言机的调用，定时执行决议
  function jccMoacAlarmCallback() public {
    // 时间戳是毫秒
    processExpire(block.timestamp.mul(1000));
  }

  // 在预言机中设置定时任务
  function setAlarm(address _alarmAddr, uint256 _type, uint256 _period) public onlyAdministrator {
    // type, begin
    IJccMoacAlarm alarm = IJccMoacAlarm(_alarmAddr);
    // 可以检查设置成功与否
    alarm.createAlarm(address(this), _type, block.timestamp, _period);
  }

  // 在预言机中删除定时任务
  function removeAlarm(address alarmAddr) public onlyAdministrator {
    IJccMoacAlarm alarm = IJccMoacAlarm(alarmAddr);
    // 可以检查设置成功与否
    alarm.removeAlarm(address(this));
  }

  event Deposit(address indexed user, uint indexed amount, uint indexed total);
  /**
  充值锁仓
  允许充值锁仓的时间限制：不设充值的限制，如果有也是在DAPP中限制，假设后来又充值了，资金提取发起提议，投票人决定
   */
  function deposit() public payable
  {
    require(!_stopDeposit, "stop deposit");
    require(!_onlyonce, "admin does not configure yet");
    require(msg.value <= MAX_VALUE && msg.value > 0, "can not deposit 100 million");

    uint total = _balanceOfDeposit.add(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value, total);
  }

  function getBalance(address _addr) public view returns (uint)
  {
    uint _d = _balanceOfDeposit.balance(_addr);
    uint _w = _balanceOfWithdraw.balance(_addr);

    return _d.sub(_w);
  }
  function getDepositBalance(address _addr) public view returns (uint)
  {
    return _balanceOfDeposit.balance(_addr);
  }
  function getDepositCount() public view returns (uint)
  {
    return _balanceOfDeposit.count();
  }
  function getDepositList(uint from, uint count) public view returns (BalanceList.element[] memory)
  {
    return _balanceOfDeposit.getList(from, count);
  }
  function getWithdrawBalance(address _addr) public view returns (uint)
  {
    return _balanceOfWithdraw.balance(_addr);
  }
  function getWithdrawCount() public view returns (uint)
  {
    return _balanceOfWithdraw.count();
  }
  function getWithdrawList(uint from, uint count) public view returns (BalanceList.element[] memory)
  {
    return _balanceOfWithdraw.getList(from, count);
  }
  // 不接受匿名的资金转账
  function() public payable {
    require(false, "never receive funds in fallback function");
  }
  // 自杀时的资金转移
  function kill() public onlyOwner {
    selfdestruct(msg.sender);
  }
}
pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

/**
 * @dev 提案投票相关基础数据结构定义.
 */
library Proposal {
  /**
  提案的数据结构
   */
  struct topic
  {
    // 提案编号:唯一性ID，可以用时间戳
    uint topicId;
    // 时间戳:可排序依据
    uint timestamp;
    // 结束时间
    uint endtime;
    // 提案类型
    uint voteType;
    // 提案发起前标的
    uint origin;
    // 提案发起后标的
    uint value;
    // 赞成票数
    uint yesCount;
    // 反对票数
    uint noCount;
    // 索引下标
    uint idx;
    // 当时有效投票人数
    uint voters;
    // 当时有效百分比
    uint percent;
    // 提案标的地址
    address target;
    // 发起提案用户
    address sponsor;
    // 是否表决通过
    bool flag;
  }

  /**
  投票明细的数据结构
   */
  struct voteDetail
  {
    // 提案ID
    uint topicId;
    // 时间戳：可排序依据
    uint timestamp;
    // 索引下标
    uint idx;
    // 投票人：一个提案只能一个人只能投一个结果
    address voter;
    // 是否同意：true同意，false不同意
    bool flag;
  }
}
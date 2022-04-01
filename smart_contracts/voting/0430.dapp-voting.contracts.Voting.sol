pragma solidity ^0.4.4;

contract Voting {

  // liyuechun -> 10
  // xietingfeng -> 5
  // liudehua -> 20
  mapping (bytes32 => uint8) public votesReceived;


  // 存储候选人名字的数组
  bytes32[] public candidateList;


  // 构造函数 初始化候选人名单
  function Voting(bytes32[] candidateNames) {

    candidateList = candidateNames;
  }

  // 查询某个候选人的总票数
  function totalVotesFor(bytes32 candidate)  constant returns (uint8) {
    require(validCandidate(candidate) == true);
    // 或者
    // assert(validCandidate(candidate) == true);
    return votesReceived[candidate];
  }

  // 为某个候选人投票
  function voteForCandidate(bytes32 candidate) {
    assert(validCandidate(candidate) == true);
    votesReceived[candidate] += 1;
  }

  // 检索投票的姓名是不是候选人的名字
  function validCandidate(bytes32 candidate) constant returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.7.0;

contract Voting {

    // liyuechun -> 10
  // xietingfeng -> 5
  // liudehua -> 20
  mapping (string => uint8) public votesReceived;

  // 存储候选人名字的数组
  string[] public candidateList;

  // 构造函数 初始化候选人名单
  constructor(string[] memory _candidateList) public{

    candidateList = _candidateList;
  }

  // 查询某个候选人的总票数
  function totalVotesFor(string memory candidate)  public view returns (uint8) {
    require(validCandidate(candidate) == true);
    // 或者
    // assert(validCandidate(candidate) == true);
    return votesReceived[candidate];
  }

  // 为某个候选人投票
  function voteForCandidate(string memory candidate) public {
    assert(validCandidate(candidate) == true);
    votesReceived[candidate] += 1;
  }

  // 检索投票的姓名是不是候选人的名字
  function validCandidate(string memory candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {

      if (keccak256(abi.encodePacked(candidateList[i])) == keccak256(abi.encodePacked(candidate))) {
        return true;
      }
    }
    return false;
  }
}

pragma solidity ^0.5.0;


contract Voting {

  mapping (uint => uint) public votesReceived;    //一个获选人编号-票数的键值对，用于记录该候选人票数
  mapping (address => bool) private addrRecoded; //投票人地址-bool类型键值对，用于判断该地址是否投过票

  uint[] public candidateList;                  //存储候选人编号，便于对输入的候选人编号进行检查

  constructor(uint[] memory candidateNums) public {  //初始化候选人
    candidateList = candidateNums;
  }

  function totalVotesFor(uint candidate) view public returns(uint) {  //返回指定编号的候选人票数
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  function voteForCandidate(uint candidate) payable public {    //给指定编号的候选人投票
    require(validCandidate(candidate));
    require(!addrRecoded[msg.sender]);
    addrRecoded[msg.sender] = true;
    uint m = msg.value / 0.1 ether;
    votesReceived[candidate] += m;
  }

  function validCandidate(uint candidate) view public returns(bool){  //判断输入的候选人编号是否合法
    for (uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}

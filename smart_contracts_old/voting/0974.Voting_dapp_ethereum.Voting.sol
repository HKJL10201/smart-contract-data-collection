pragma solidity ^0.6.4;
// @dev 컴파일러 버전을 명시하는 부분

contract Voting {

  mapping (bytes32 => uint256) public votesReceived;

  bytes32[] public candidateList;

  // @dev 컨트랙트를 블록체인에 배포할때 딱 한번 호출되는 생성자
  constructor(bytes32[] memory candidateNames) public {
    candidateList = candidateNames;
  }

  // 총 투표받은 수를 표시함.
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // 있는 사람인지 확인 후 투표 대상의 투표수를 올려줌
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }

  // 있는 사람인지 확인시켜주는 함수.
  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}
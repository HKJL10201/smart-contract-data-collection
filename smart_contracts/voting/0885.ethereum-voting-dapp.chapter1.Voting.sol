pragma solidity ^0.4.23;

contract Voting {
  // 해야하는 것들
  // 1. constructor to initialize candidates
	// 2. vote for candidates
	// 3. get count of votes for each candidates
    bytes32[] public candidateList;
    mapping (bytes32 => uint8) public votesReceived;
    constructor(bytes32[] candidateNames) public{
        // 아직 배열이나 스트링을 지원하지 않기 때문에 bytes32사용
        // 생성자는 컨트랙이 배포될때 딱 한번만 배포. 이후 수정,덮어쓰기 불가
        candidateList = candidateNames;
    }
    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate)); // 유효성검사, false면 다음 행으로 넘어가지않음.(컨트랙실행x)
        votesReceived[candidate] += 1;
    }

    function totalVotesFor(bytes32 candidate) public view returns(uint8){
        // view: 단순 읽기 전용함수 (컨트랙의 상태를 바꾸지 않음)
        return votesReceived[candidate];
    }
    // 후보 유효성검사
    function validCandidate(bytes32 candidate) view public returns(bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}
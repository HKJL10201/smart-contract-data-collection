pragma solidity ^0.7.4;

contract Voting {
    
    // uint8 정수형 타입으로 맵핑
    mapping (bytes32 => uint8) public votesReceived;

    // bytes32 배열 선언
    bytes32[] public candidateList;
    bytes32[] public terminalKeyList;

    // 스마트 컨트랙트 생성자
    constructor(bytes32[] memory candidateNames, bytes32[] memory terminalKeys) public {
        candidateList = candidateNames;
        terminalKeyList = terminalKeys;
    }
    
    // 후보자 유효성 판별 모듈
    function validCandidate(bytes32 candidate) view public returns (bool) {
        for(uint i=0; i < candidateList.length; i++){
            if(candidateList[i] == candidate) {
                return true;
            } 
        }
        return false;
    }

    // 단말기 유효성 판별 모듈
    function validTerminal(bytes32 terminalKey) view public returns (bool) {
        for(uint i=0; i < terminalKeyList.length; i++){
            if(terminalKeyList[i] == terminalKey) {
                return true;
            } 
        }
        return false;
    }

    // 투표 모듈
    function voteForCandidate(bytes32 candidate, bytes32 terminalKey) public {
        require(validCandidate(candidate) && validTerminal(terminalKey));
        votesReceived[candidate] += 1; 
    }
    
    // 후보자 누적 투표값 가져오기 모듈
    function totalVotesFor(bytes32 candidate) view public returns(uint8) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }
}

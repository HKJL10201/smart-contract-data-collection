// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Voting {
    bytes32[] public candidateList; // 후보자 리스트
    mapping(bytes32 => uint8) public votesReceived; // 각 후보자 해시형 득표수 (kim -> 10)

    constructor(bytes32[] memory candidateNames) {
        candidateList = candidateNames;
    }

    /**
    function 총 3개

    1. voteForCandidate : 특정 후보자에게 투표하면 득표수 + 1 되는 함수
    2. totalVotesFor(읽기 전용) : 각 후보자의 전체 득표수
    3. validCandidate(읽기 전용) : 후보자 리스트에 존재하는 후보자인지 유효성 검사
     */

    function voteForCandidate(bytes32 candidate) public {
        require(validCandidate(candidate));
        votesReceived[candidate] += 1;
    }

    function totalVotesFor(bytes32 candidate) public view returns (uint8) {
        require(validCandidate(candidate));
        return votesReceived[candidate];
    }

    function validCandidate(bytes32 candidate) public view returns (bool) {
        for (uint256 i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}

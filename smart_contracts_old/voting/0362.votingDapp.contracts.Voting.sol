// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {
  
  // 구조체
  struct Candidate {
    uint256 number;
    string name;
    string party;
  }

  // 구조체의 배열
  Candidate[] public candidates;

  // 후보자 등록 함수
  function registerCandidate (uint256 _number, string memory _name, string memory _party) public {
    candidates.push(Candidate(_number, _name, _party));
  }

  // 후보자 정보 조회
  function getCandidates(uint256 _number) public view returns (uint256 getNumber, string memory getName, string memory getParty) {
    getNumber = candidates[_number].number;
    getName = candidates[_number].name;
    getParty = candidates[_number].party;
  }

}
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;
pragma experimental ABIEncoderV2;

contract Election { // 후보자 등록 : 원래는 선관위 정도, 여기서는 컨트랙트 구동자

    string public name;
    string public ElectionName;

    // 후보자 구조체
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // 후보자 매핑   위구조체 Candidate
    // mapping(uint => Candidate) public candidates;
    Candidate[] public candidates;

    // 투표했는지 안했는지 boolean으로
    mapping(address => bool) public voters;

    // 후보자 득표수
    uint public candidatesCount = 0;
    // 후보자별 득표수 -> 이름이 중복되면 고려하지 않음 (중복 등록 불가)
    // mapping(string => uint) scores;

    // 생성자 : 선거 계약 생성 중 변수 및 데이터 설정
    constructor(string memory _ElectionName, string memory _candidate) {
        // require(_candidates.length > 0, "There should be atleast 1 candidate.");
        ElectionName = _ElectionName;
        // description = _nda[1];
        candidates.push(Candidate(0, _candidate, 0)); //(id, name, voteCount)
        candidatesCount++;
    }

    // 후보 추가를 위한 private function
    function addCandidate (string memory _name) private {
        require(candidates.length < 5);
        uint id = candidates.length;
        // 후보자 등록
        candidates.push(Candidate(id, _name, 0));
        // 후보자 수 증가
        candidatesCount++;
    }

    // 후보자에게 투표하기 위한 vote function
    function vote(uint _candidate) public {
        // => 투표용 디앱(컨트랙트)를 구동한자가 투표자
        require(!voters[msg.sender], "Voter has already Voted!");
        require(_candidate < candidatesCount && _candidate >= 0, "Invalid candidate to Vote!");
        // 투표 진행 
        voters[msg.sender] = true;
        // 투표수 증가
        candidates[_candidate].voteCount++;
        // total 득표수 증가
        // numVote++;
        // emit sendMsg("투표 complete");
   
    }

}
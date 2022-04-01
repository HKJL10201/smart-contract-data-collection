pragma solidity >=0.4.22 <0.8.0;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
  // Read/write Candidates
    // mapping의 key값은 unsigned integer 데이터 타입
    // value값은 우리가 조금 전에 정의한 Candidate 구조체
    // 이로써 우리는 후보자들의 id(uint)로 후보자를 조회할 수 있게 되었다
    // 우리가 만든 후보자 mapping은 contract 하위에 위치한 state variable(Java에서의 전역변수와 유사)(반대되는 개념: local variable)이기 때문에
    // 새로운 key-value로 언제든지 블록체인에 데이터를 기록할 수 있다
    // 또한 public으로 선언했기 때문에 getter function을 자동으로 갖게되어 외부에서 함수 호출만으로 조회가 가능하다

    // Read/write candidates
    mapping(uint => Candidate) public candidates;
    // 후보자 Counter 선언
    // Store Candidates Count
    // 선거에 참여하는 후보자들의 수 변수 선언
    // Store Candidates Count
    uint public candidatesCount;

    constructor() public {
        addCandidate("배성민");
        addCandidate("김해람");
        addCandidate("서홍석");
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
}
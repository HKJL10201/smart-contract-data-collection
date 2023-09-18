pragma solidity ^0.5.0;

import "./safemath.sol";
import "./ownable.sol";

contract VotingFactory is Ownable {
    
    //voting컨트랙트를 담을 수 있는 배열 
    Voting[] private votings;
    
    //voting컨트랙트 생성
    function createVoting() public {
        Voting voting = new Voting(msg.sender); 
        votings.push(voting);
    }
    
    //만들어진 voting컨트랙트 불러오기
    function getVoting() public view returns (Voting[] memory) {
        return votings;
    } 
}

contract Voting is Ownable{
    
    //후보자 구조체
    struct Candidate{
        string name;
        string description;
        uint32 count;
    }
    
    //후보자 등록 이벤트 발생
    event NewCandidate(uint candidateId, string name);
    
    //후보자 구조체를 담을 수 있는 배열
    Candidate[] public candidates;
    
    //mapping (bytes32 => uint8) public votesReceived;
    
    //voting컨트랙트를 생성한 사용자의 address
    address public manager;
    
    
    //Voting컨트랙트 생성자
    constructor(address mgr) public {
        manager = mgr;
    }
    
    // 등록된 후보자의 주소
    mapping (uint => address) public candidateToOwner;

    // 등록된 후보자의 등록번호
    mapping (address => uint) ownerCandidateCount;
    
    
    /*
    constructor(bytes32[] memory candidateNames) public {
        candidateList = candidateNames;
    }
    */

    // 후보등록 기능
    // manager만 가능
    function createCandidate(string memory _name, string memory _description) public {
        uint id = candidates.push(Candidate(_name, _description, 0)) -1;
        candidateToOwner[id] = msg.sender;
        ownerCandidateCount[msg.sender]++;
        emit NewCandidate(id, _name);
    } 
    
    //후보에 투표하기
    function voteForCandidate(uint _candidateId) public {
        candidates[_candidateId].count++;
    }
    
    //후보자에 대한 총 득표수
    function totalVotesFor(uint _candidateId) view public returns(uint32){
        return candidates[_candidateId].count;
    }
    
    /*
    function validCandidate(string memory _candidate) view public returns(bool){
        for(uint i=0; i < candidates.length; i++ ){
            if( candidates[i].name == _candidate) {
                return true;
            }
        }
        return false;
    }
    */

}
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {
  address public owner;
  address payable winCandidate;

  uint256 private _currentElectionId;
  uint256 public totalTime = 3 days;
  uint256 public endTime;
  uint256 public maxVotes;
  
  constructor()  {
    owner = msg.sender;
  }

  mapping(uint256 => mapping(address => Vote)) public _votes;
  mapping(uint256 => mapping(uint256 => Candidate)) public _candidate;
  mapping(uint256 => Election) public _election;

  

  modifier requireOwner() {
    require(owner == msg.sender, "No access");
    _;
  }

  enum ElectionStatus {
    COMPLETED,
    ACTIVE
  }

  event NewElection(uint256 indexed index);
  event Voted(uint indexed id, address indexed voter);
  event Withdraw(address indexed account, uint256 amount);
  event ElectionFinished(uint256 indexed id,ElectionStatus electionStatus);

  struct Candidate {
    string name;
    address payable candidateAddress;
    uint numberVotes;
  }
  struct Vote {
    address voteAddress;
    bool isVoted;
  }
  struct Election {
    string description;
    uint256 endTimeOfElecting;
    ElectionStatus status;
    uint256 numberOfVotes;
    uint256 numberOfCandidate;
    string[] listCandidate; 
    uint256 deposit;
    uint256 comission;
  }

  function createElection(string memory description) public requireOwner returns (uint256){
    uint256 electionId =_currentElectionId++;
    Election storage election = _election[electionId];
    election.description = description;
    election.endTimeOfElecting = block.timestamp + totalTime;
    election.status = ElectionStatus.ACTIVE;

    emit NewElection(electionId);
    return electionId;
  }

 
  function addCandidate(uint electionId,string memory _name, address payable _adrCandidate) public {
    require(_election[electionId].status==ElectionStatus.ACTIVE,"Voting is not ACTIVE");
    require(_election[electionId].endTimeOfElecting >= block.timestamp,"Start voting first.");
    
    for (uint256 i = 0; i < _election[electionId].numberOfCandidate; i++) {
      if(_adrCandidate == _candidate[electionId][i].candidateAddress){
        revert("The address already exists");
      }
    }
    _candidate[electionId][_election[electionId].numberOfCandidate].name = _name;
    _candidate[electionId][_election[electionId].numberOfCandidate].candidateAddress = _adrCandidate;

    _election[electionId].numberOfCandidate++;
  }

  function vote(uint electionId, uint candidate) public payable {
    require(_currentElectionId >= electionId, "Voting does not exist");
    Election storage election = _election[electionId];
    require(election.endTimeOfElecting >= block.timestamp,"The voting is over");
    require(!_votes[electionId][msg.sender].isVoted,"Have you already voted");
    require(msg.value >= .01 ether,"Insufficient funds for voting" );

    _election[electionId].deposit += msg.value;
    _election[electionId].numberOfVotes++;

    _votes[electionId][msg.sender].isVoted = true;
    _votes[electionId][msg.sender].voteAddress = msg.sender;

    _candidate[electionId][candidate].numberVotes++;

    emit Voted(electionId, msg.sender);
  }

  //Показать список кандидатов
  function listCandidate(uint256 electionId) external returns (string[] memory){
    for (uint256 i = 0; i < _election[electionId].numberOfCandidate; i++) {
    _election[electionId].listCandidate.push(_candidate[electionId][i].name);
    }
    return _election[electionId].listCandidate;
  }

  //До конца голосования
  function timeLeft (uint elactionId) public returns(uint256){
    endTime = _election[elactionId].endTimeOfElecting - block.timestamp;
    return endTime;
  }
  
  //Инфо про кандитатов
  function infCandidate(uint8 electionId, uint candidate) external view returns (Candidate memory candidates){
    return _candidate[electionId][candidate];
  }

  //Инфо про любого кто голосовал
  function infVoter(uint8 electionId,address voter) external view returns (Vote memory votes){
    return _votes[electionId][voter];
  }

  //Инфо про одно из голосований
  function infElection(uint8 electionId) external view returns (Election memory election){
    return _election[electionId];
  }
 
  //Вывести комиссию
  function withdrawComission(uint electionId, address payable _to) public requireOwner{
    require(_election[electionId].status==ElectionStatus.COMPLETED,"Voting is still ACTIVE");
    _to.transfer(_election[electionId].comission);
    _election[electionId].comission = 0;
  }

  //Завершить голосование и отправить комиссию кому угодно
  function finishElection(uint256 electionId) public {
    require(_election[electionId].status == ElectionStatus.ACTIVE,"Voting is still underway.");
    require(_election[electionId].endTimeOfElecting <= block.timestamp,"Voting is active.");
    

    for (uint256 i = 0; i < _election[electionId].numberOfCandidate; i++) {
      if(_candidate[electionId][i].numberVotes > maxVotes){
        maxVotes = _candidate[electionId][i].numberVotes;
        winCandidate = _candidate[electionId][i].candidateAddress;
      }
    }

    _election[electionId].comission = _election[electionId].deposit / 10;
    _election[electionId].deposit -= _election[electionId].comission;

    winCandidate.transfer(_election[electionId].deposit);

    _election[electionId].deposit = 0;

    _election[electionId].status = ElectionStatus.COMPLETED;
    emit ElectionFinished(electionId,_election[electionId].status);
  } 
}
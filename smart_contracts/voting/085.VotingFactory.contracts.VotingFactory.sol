// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";


contract VotingFactory is Ownable {

  event CreateNewVotingEvent(uint256 votingId, string name, uint256 startDate);
  event NewVotedEvent(uint256 votingId, address account, address candidate);

  struct Voting {
    string name;
    uint256 startDate;
    bool isActive;
  }

  struct Candidate {
    address account;
    uint256 voteCount;
  }
  
  mapping(uint256 => Candidate[]) public votingIdToCandidates;
  mapping(uint256 => address[]) public votingIdToVoter;
  mapping(uint256 => uint256) public votingIdCount;
  
  Voting[] public voting;

  uint256 finishDays = 3 days;
  uint256 voteFee = 0.01 ether;


  modifier isActive(uint256 _votingId) {
    require(voting[_votingId].isActive, "The Voting is finished");
    _;
  }

  // любой может голосовать только 1 раз в 1 голосовании
  function vote(uint256 _votingId, address _candidate) external payable isActive(_votingId) {
    // проверить оплату
    require(msg.value == voteFee, "Required fee 0.01 ether.");

    // за себя голосовать нельзя
    require(_candidate != msg.sender, "Self-delegation is disallowed.");    

    // проверить, если ли кандидат в списке голосования
    require(isCandidateInVoting(_votingId, _candidate), "The candidate is not on the voting list.");
    
    // проверить, голосующий голосовал уже в этом голосовании
    require(isVoterInVoting(_votingId, msg.sender), "The voter already voted.");
    
    // добавить в список голосовавших
    votingIdToVoter[_votingId].push(msg.sender);

    // увеличить количество проголосовавших
    votingIdCount[_votingId]++;

    // проголосовать за кандидата
    addVoteToCandidate(_votingId, _candidate);

    emit NewVotedEvent(_votingId, msg.sender, _candidate);
  }


  // любой может завершить голосование по завершению 3 дней
  function finishVoting(uint256 _votingId) external payable isActive(_votingId) {
    // определить кто выиграл голосование
    (bool isWinner, address winner) = getWinner(_votingId);
    
    require(isWinner, "There is no winner");
    require(block.timestamp > voting[_votingId].startDate + finishDays, 'It`s no time to finish'); 

    // выключить голосование
    voting[_votingId].isActive = false;

    // подсчитать выигрыш, пример проголосовало 4
    // скинули на голосование эфира ( 1 / 100 * 4 ) = 0.04
    // 10% коммисии 0.04 / 10 = 0.004
    // отправить победителю 0.04 - 0.004 = 0.036
    uint256 amount = votingIdCount[_votingId] / 100;
    uint256 prise = amount - (amount / 10);

    // отправить выигрыш победителю
    payable(winner).transfer(prise);
  }


  function isVoterInVoting(uint256 _votingId, address _voter) public view returns (bool){
    for (uint i = 0; i < votingIdToVoter[_votingId].length; i++) {
      if (votingIdToVoter[_votingId][i] == _voter) {
        return false;
      }
    }
    return true;  
  }


  function isCandidateInVoting(uint256 _votingId, address _candidate) public view returns (bool){
    for (uint256 i = 0; i < votingIdToCandidates[_votingId].length; i++) {
      if (votingIdToCandidates[_votingId][i].account == _candidate) {
        return true;
      }
    }
    return false;
  }


  function addVoteToCandidate(uint256 _votingId, address _candidate) private {
    for (uint256 i = 0; i < votingIdToCandidates[_votingId].length; i++) {
      if (votingIdToCandidates[_votingId][i].account == _candidate) {
        votingIdToCandidates[_votingId][i].voteCount++;
      }
    }
  }  


  function getWinner(uint256 _votingId) private view returns (bool, address){
    bool isWinner = false;
    uint256 largest = 0;
    address winner;

    for (uint i = 0; i < votingIdToCandidates[_votingId].length; i++) {     

      if(votingIdToCandidates[_votingId][i].voteCount > largest){
        isWinner = true;
        largest = votingIdToCandidates[_votingId][i].voteCount;
        winner = votingIdToCandidates[_votingId][i].account;
      }
      
    }
    
    return (isWinner, winner);
  }
  

  // ============= only admin routes =============

  function createVoting(string memory _name) external onlyOwner {
    voting.push(Voting(_name, block.timestamp, true));

    uint256 votingId = voting.length - 1;
    emit CreateNewVotingEvent(votingId, _name, block.timestamp);
  }


  function addCandidate(address _candidate, uint256 _votingId) external onlyOwner {
    // проверить, если ли кандидат в списке голосования
    require(!isCandidateInVoting(_votingId, _candidate), "The candidate is already on the voting list.");

    votingIdToCandidates[_votingId].push(Candidate(_candidate, 0));
  }


  function withdraw() external payable onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }  
}


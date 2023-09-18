//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingContract is Ownable {

  uint256 public votingPrice;
  uint256 public commission; // in percents
  uint256 private ownerAmount;
  uint public limitDays; // days for vote

  struct Candidate {
    string candidateName;
    string candidateProgram;
  }

  mapping(address => Candidate) public candidates;

  uint256 public numberOfVotes;

  struct Vote {
    bool actual;
    uint startTime;
    uint256 condidatesNumber;
    uint256 votersNumber;
    uint256 amount;
    address winner;
    mapping(uint256 => address) candidateOnTheVote;
  }

  /* Mapping through votingId to a vote */
  mapping(uint256 => Vote) public votes;
  /* Mapping through votingId to a candidate on a vote*/
  mapping(uint256 => mapping(address => bool)) public candidateOnVote;
  /* Mapping through votingId to how many votes candidates got on a vote */
  mapping(uint256 => mapping(address => uint256)) public votingBalance;
  /* Mapping through votingId to voters who particepated on a vote*/
  mapping(uint256 => mapping(address => bool)) public voters;

  string  public name;
  string  public symbol;


  event yourVoteCounted(uint256 _votingId);

  /**
   * @dev Initializes the contract parameters.
   */
  constructor(string memory _name, string memory _symbol){
    name = _name;
    symbol = _symbol;
    numberOfVotes = 0;
    ownerAmount = 0;
    votingPrice = 10000000000000000;
    commission = 10;
    limitDays = 3;
  }

  /**
   * @dev Add candidate to the common list. May only be called by owner.
   * @param _address address of candidate
   * @param _candidateName name of candidate
   * @param _candidateProgram may containe some description of anything
   */
  function addCondidate(
    address _address,
    string memory _candidateName,
    string memory _candidateProgram) public onlyOwner {
    require(bytes(_candidateName).length != 0, "The candidate must have a name");
    require(bytes(candidates[_address].candidateName).length == 0, "This condidate is already on the list");
    candidates[_address] = Candidate(
      {
        candidateName: _candidateName,
        candidateProgram: _candidateProgram
      }
    );
  }

  /**
   * @dev Edit candidate parameters. May only be called by owner.
   * @param _address address of candidate
   * @param _candidateName name of candidate
   * @param _candidateProgram may containe some description of anything
   */
  function editCondidate(
    address _address,
    string memory _candidateName,
    string memory _candidateProgram) public onlyOwner {
    require(bytes(candidates[_address].candidateName).length != 0, "There is no condidate with this address");
    candidates[_address] = Candidate(
      {
        candidateName: _candidateName,
        candidateProgram: _candidateProgram
      }
    );
  }

  /**
   * @dev Add new voting. May only be called by owner.
   * @param _candidateAccounts addresses of candidates of the vote
   */
  function addVoting(address[] memory _candidateAccounts) public onlyOwner {
    uint256 votingId = numberOfVotes;
    Vote storage v = votes[votingId];
    v.startTime = block.timestamp;
    v.condidatesNumber = _candidateAccounts.length;
    v.actual = true;
    v.amount = 0;
    v.votersNumber = 0;
    v.winner = address(0);
    for (uint i = 0; i < _candidateAccounts.length; i++) {
      require(bytes(candidates[_candidateAccounts[i]].candidateName).length != 0,
        "The accaunt of one of a candidate is not correct");
      v.candidateOnTheVote[i] = _candidateAccounts[i];
      candidateOnVote[votingId][_candidateAccounts[i]] = true;
    }
    numberOfVotes++;
  }

  /**
   * @dev Vote. Everyone can vote, but only once.
   * @param _votingId ID of the vote
   * @param _candidateAccount addresses of candidates of the vote
   */
  function vote(uint256 _votingId, address _candidateAccount) public payable {
    uint nowTime = block.timestamp;
    Vote storage v = votes[_votingId];
    require(v.startTime != 0, "There is no vote with this id");
    require(nowTime < (v.startTime + limitDays * 1 days), "This vote is over");
    require(!voters[_votingId][msg.sender], "You already voted");
    require(candidateOnVote[_votingId][_candidateAccount],
      "This candidate is not particepating in this vote");
    require(msg.value == votingPrice, "Not enaught or too much ethers");
    votingBalance[_votingId][_candidateAccount] += 1;
    voters[_votingId][msg.sender] = true;
    v.votersNumber += 1;
    v.amount += votingPrice;
    emit yourVoteCounted(_votingId);
  }

  /**
   * @dev Get owner's profit amount. May only be called by owner.
   * @return ownerAmount variable;
   */
  function getOwnerAmount() public view onlyOwner returns(uint256) {
    return ownerAmount;
  }

  /**
   * @dev Transfer profit from contract to owner. May only be called by owner.
   * @param _amount Part of ownerAmount
   */
  function takeProfit(uint256 _amount) public onlyOwner {
    require(ownerAmount > 0, "Nothing to take");
    require(_amount <= ownerAmount, "The amount requested is too high");
    address owner = owner();
    payable(owner).transfer(_amount);
    ownerAmount -= _amount;
  }

  /**
   * @dev Stop vote. Everyone can stop vote if the time has come.
   * @param _votingId ID of the vote
   */
  function stopVote(uint256 _votingId) public {
    uint nowTime = block.timestamp;
    Vote storage v = votes[_votingId];
    require(v.actual, "The vote was already stopped");
    require(nowTime > (v.startTime + limitDays * 1 days), "Not yet time");
    if (v.votersNumber > 0) {
      address winner = sumUpTheVoteAndGetTheWinner(_votingId);
      v.winner = winner;
      uint256 ownerCash = v.amount / commission;
      ownerAmount += ownerCash;
      uint256 winnerCash = v.amount - ownerCash;
      payable(winner).transfer(winnerCash);
    }
    v.actual = false;
  }

  /* There is some ambiguous in the test item because it can be multiple winning
  candidates who get the same number of votes. In this case, there are two ways:
  one of them is pick a winner with a pseudo-random function. Another way is to
  divide money into equal parts.
  In this function the first method is aplied, because there was only one winner
  in the picture in the task ))*/
  /**
   * @dev Sum up of the vote.
   * @param _votingId ID of the vote
   */
  function sumUpTheVoteAndGetTheWinner(uint256 _votingId) private view
  returns (address winner) {
    Vote storage v = votes[_votingId];
    uint256 maxNumVotes = 0;
    uint256 curNumVotes;
    uint256 numOfWiners = 0;
    address[] memory winners = new address[](v.condidatesNumber);
    /* Search the maximum number of votes */
    for (uint i = 0; i < v.condidatesNumber; i++) {
      curNumVotes = votingBalance[_votingId][v.candidateOnTheVote[i]];
      if(maxNumVotes < curNumVotes) {
        maxNumVotes = curNumVotes;
      }
    }
    /* Search candinates who have the  maximum number of votes (they can be a few)*/
    for (uint i = 0; i < v.condidatesNumber; i++) {
      curNumVotes = votingBalance[_votingId][v.candidateOnTheVote[i]];
      if(maxNumVotes == curNumVotes) {
        winners[numOfWiners] = v.candidateOnTheVote[i];
        numOfWiners++;
      }
    }
    if (numOfWiners > 1) {
      winner = winners[random(numOfWiners)];
    }
    else{
      winner = winners[0];
    }
  }

  /**
   * @dev The conventional pseudo-random function.
   * @param _playersCount range of random number
   * @return pseudo-random value
   */
  function random(uint256 _playersCount) private view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%(_playersCount-1);
  }

  /**
   * @dev Get remaining voting time. Everyone can stop vote if the time has come.
   * @param _votingId ID of the vote
   * @return days_
   * @return hours_
   * @return minutes_
   * @return seconds_
   */
  function getRemainingTime(uint256 _votingId) public view
  returns (uint days_, uint hours_, uint minutes_, uint seconds_) {
    Vote storage v = votes[_votingId];
    require(v.startTime != 0, "There is no vote with this id");
    uint limitTime = v.startTime + limitDays * 1 days;
    uint nowTime = block.timestamp;
    if(nowTime >= limitTime) {
      days_ = 0;
      hours_ = 0;
      minutes_ = 0;
      seconds_ = 0;
    }
    else {
      uint leftTime = limitTime - nowTime;
      days_ = leftTime / 1 days;
      if(leftTime >= 1 days) {
        leftTime = leftTime % 1 days;
      }
      hours_ = leftTime / 1 hours;
      if(leftTime >= 1 hours) {
        leftTime = leftTime % 1 hours;
      }
      minutes_ = leftTime / 1 minutes;
      if(leftTime >= 1 minutes) {
        leftTime = leftTime % 1 minutes;
      }
      seconds_ = leftTime;
    }
  }

  function getCandidateOnTheVote(uint256 _votingId, uint256 _candId) public view returns (address) {
    Vote storage v = votes[_votingId];
    return v.candidateOnTheVote[_candId];
  }
}

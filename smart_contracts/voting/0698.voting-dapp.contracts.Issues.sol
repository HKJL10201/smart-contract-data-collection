pragma solidity >=0.4.21 <0.6.0;

contract Issues {
  uint issueCount = 0;

  event VoteCast(address voter, uint issueId, bytes32 choice);
  event IssueCreated(address creator, bytes32 issue, bytes32 choices);

  bytes32[] issues;
  bytes32[] choices;
  Vote[] votes;

  struct Vote {
    uint issueId;
    address voter;
    bytes32 choice;
  }

  function createIssue(bytes32 _issue, bytes32 _choices) public {
    issues.push(_issue);
    choices.push(_choices);
    issueCount++;
    emit IssueCreated(msg.sender, _issue, _choices);
  }

  function getIssueCount() public view returns (uint) {
    return issueCount;
  }

  function getIssues() public view returns(bytes32[] memory) {
    return issues;
  }

  function getChoices() public view returns(bytes32[] memory) {
    return choices;
  }

  function getVotes() public view returns(uint[] memory, address[] memory, bytes32[] memory) {
    uint[] memory ids = new uint[](votes.length);
    address[] memory voters = new address[](votes.length);
    bytes32[] memory vchoices = new bytes32[](votes.length);
    for(uint i = 0; i < votes.length; i++) {
      ids[i] = votes[i].issueId;
      voters[i] = votes[i].voter;
      vchoices[i] = votes[i].choice;
    }
    return (ids, voters, vchoices);
  }

  function castVote(bytes32 _choice, uint _issueId) public canVote(_issueId) {
    Vote memory vote = Vote(_issueId, msg.sender, _choice);
    votes.push(vote);
    emit VoteCast(msg.sender, _issueId, _choice);
  }

  modifier canVote (uint _issueId) {
    bool voted = false;
    for(uint i = 0; i < votes.length; i++) {
      if(votes[i].issueId == _issueId && votes[i].voter == msg.sender){
        voted = true;
      }
    }
    require(voted == false, "You've already voted on this issue.");
    _;
  }
}

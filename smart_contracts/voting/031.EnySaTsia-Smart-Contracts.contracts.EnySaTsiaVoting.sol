pragma solidity ^0.5.0;

import "./Ownable.sol";

contract EnySaTsiaVoting is Ownable {

  bytes public name;
  bool public sessionOpen;
  bytes[] public questions;

  mapping(bytes32 => bool) public voteOpen;
  mapping(address => mapping(bytes32 => bytes)) public votes;

  event StartVote(bytes32 indexed session, bytes32 indexed question);
  event CloseVote(bytes32 indexed session, bytes32 indexed question);
  event StartSession(bytes32 indexed session);
  event CloseSession(bytes32 indexed session);
  event Vote(bytes32 indexed session, bytes32 indexed question, bytes decision);
  event CreateQuestion(bytes32 indexed session, bytes32 indexed question);

  constructor(bytes memory _name) public {
    name = _name;
  }

  modifier validQuestion(bytes memory question) {
    require(
      isValidQuestion(question),
      "This Question already exists!"
    );
    _;
  }

  modifier sessionIsActive() {
    require(
      sessionOpen,
      "Please start session!"
    );
    _;
  }

  modifier votingIsActive(bytes memory question) {
    require(
      voteOpen[sha256(question)],
      "Please start vote!"
    );
    _;
  }

  function isValidQuestion(bytes memory question) public view returns(bool) {
    for (uint i = 0; i < questions.length; i++) {
      if (sha256(questions[i]) == sha256(question)) {
        return false;
      }
    }
    return true;
  }

  function changeSessionName(bytes memory _name) public onlyOwner {
    name = _name;
  }

  function startSession() public onlyOwner {
    sessionOpen = true;
    emit StartSession(sha256(name));
  }

  function closeSession() public onlyOwner {
    sessionOpen = false;
    emit CloseSession(sha256(name));
  }

  function createQuestion(bytes memory question) public onlyOwner sessionIsActive validQuestion(question) {
    questions.push(question);
    emit CreateQuestion(sha256(name), sha256(question));
  }

  function changeQuestion(bytes memory question, bytes memory sentense) public onlyOwner {
    for (uint i = 0; i < questions.length; i++) {
      if (sha256(questions[i]) == sha256(question)) {
        questions[i] = sentense;
      }
    }
  }

  function startVote(bytes memory question) public onlyOwner sessionIsActive {
    voteOpen[sha256(question)] = true;
    emit StartVote(sha256(name), sha256(question));
  }

  function closeVote(bytes memory question) public onlyOwner sessionIsActive {
    voteOpen[sha256(question)] = false;
    emit CloseVote(sha256(name), sha256(question));
  }

  function vote(bytes memory decision, bytes memory question) public sessionIsActive votingIsActive(question) {
    votes[msg.sender][sha256(question)] = decision;
    emit Vote(sha256(name), sha256(question), decision);
  }

  function countQuestions() public view returns(uint256) {
    return questions.length;
  }

}

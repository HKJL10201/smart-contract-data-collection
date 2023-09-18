pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import './interfaces/CulturestakeI.sol';

contract Question {
  address private masterCopy;

  using SafeMath for uint256;

  address public admin;
  bytes32 public id;
  bytes32 public festival;
  uint256 public maxVoteTokens;
  uint256 public votes;
  bool public configured;
  mapping (bytes32 => Answer) answers;
  mapping (address => bool) public hasVoted;

  struct Answer {
    bool inited;
    bool deactivated;
    bytes32 answer;
    uint256 votePower;
    uint256 voteTokens;
    uint256 votes;
  }

  event InitAnswer(bytes32 questionId, bytes32 indexed answer);
  event DeactivateAnswer(bytes32 questionId, bytes32 indexed answer);
  event Vote(
    bytes32 questionId,
    bytes32 indexed answer,
    uint256 voteTokens,
    uint256 votePower,
    uint256 votes,
    address booth,
    uint256 nonce
  );

  /// @dev Asserts that the caller is an admin of the culturestake hub
  modifier authorized() {
      require(CulturestakeI(admin).isOwner(msg.sender), "Must be an admin" );
      _;
  }

  /// @dev Asserts that the caller is the vote relayer in the culturestake hub
  modifier onlyVoteRelayer() {
      require(CulturestakeI(admin).isVoteRelayer(msg.sender), "Must be the vote relayer" );
      _;
  }

  /// @dev Sets the main configuration params of the question - this is done primarily to avoid modifying the formally verified proxy
  /// @param _admin Address set automatically to be the culturestake hub that deployed this question
  /// @param _question The question chain id
  /// @param _maxVoteTokens The amount of vote tokens given to each voter per answer
  /// @param _festival The festival chain id the question is associated with
  /// @return Bool for if the booth was initialized
  function setup(
    address _admin,
    bytes32 _question,
    uint256 _maxVoteTokens,
    bytes32 _festival
  ) public {
    // method can only be called once
    require(!configured, "This question has already been configured");
    admin = _admin;
    id = _question;
    maxVoteTokens = _maxVoteTokens;
    festival = _festival;
    configured = true;
  }

  /// @dev Calls to culturestake hub to check that this question hasn't been shut down
  /// @return True if this question has not been manually deactivated
  function thisQuestionIsActive() public view returns (bool) {
    (, bool deactivated, , , ) = CulturestakeI(admin).getQuestion(id);
    return !deactivated;
  }

  /// @dev Registers a new answer for this question
  /// @param _answer The answer chain id
  function initAnswer(bytes32 _answer) public authorized {
    require(configured, "Question must be configured");
    require(thisQuestionIsActive(), "Question must be active");
    answers[_answer].inited = true;
    answers[_answer].answer = _answer;
    emit InitAnswer(id, _answer);
  }

  /// @dev Destructive method, removes an answer from voting
  /// @param _answer The answer chain id
  function deactivateAnswer(bytes32 _answer) public authorized {
    require(configured, "Question must be configured");
    answers[_answer].deactivated = true;
    emit DeactivateAnswer(id, _answer);
  }

  /// @dev Getter for a answer struct
  /// @param _answer The answer chain is
  /// @return Bool for if the answer was initialized
  /// @return Bool for if the answer was deactivated
  /// @return The total vote power this answer received
  /// @return The total vote tokens this answer received
  /// @return The total users who engaged with this answer
  function getAnswer(bytes32 _answer) public view returns (bool, bool, uint256, uint256, uint256) {
    return (
      answers[_answer].inited,
      answers[_answer].deactivated,
      answers[_answer].votePower,
      answers[_answer].voteTokens,
      answers[_answer].votes
    );
  }

  /// @dev Records a vote without checking the voting booth signature on chain, can only be called by vote relayer
  /// @param _answers An array of the answer chain ids
  /// @param _answers An array of the vote tokens awarded to each answer, in the same order
  /// @param _answers An array of the vote powers awarded to each answer, in the same order
  /// @param _answers The address of the booth that the vote was placed at
  /// @param _answers The nonce that this vote used
  function recordUnsignedVote(
    bytes32[] memory _answers,
    uint256[] memory _voteTokens,
    uint256[] memory _votePowers,
    address _booth,
    uint256 _nonce
  ) public onlyVoteRelayer returns (bool) {
    require(configured, "Question must be configured");
    // this method assumes most checks have been done by an admin
    for (uint i = 0; i < _answers.length; i++) {
      answers[_answers[i]].votes = answers[_answers[i]].votes.add(1);
      answers[_answers[i]].voteTokens = answers[_answers[i]].voteTokens.add(_voteTokens[i]);
      answers[_answers[i]].votePower = answers[_answers[i]].votePower.add(_votePowers[i]);
      // the first time a nonce is used it is burned, but the vote relayer can still transit the other
      // half of the vote package because this vote method will not fail if nonce has already
      // been burned. This means further vote sttempts sent to the server will fail, but the
      // rest of the current vote can still be completed
      CulturestakeI(admin).burnNonce(_booth, _nonce);
      emit Vote(id, _answers[i], _voteTokens[i], _votePowers[i], answers[_answers[i]].votes, _booth, _nonce);
    }
    return true;
  }
}
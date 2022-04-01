pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vote {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event QuestionAdded(address indexed from, uint256 questionKey);
    event AnswerAdded(address indexed from, uint256 questionKey, uint256 answerKey);
    event Voted(address indexed from, uint256 questionKey, uint256 answerKey, uint256 votes);
    event Withdrawn(address indexed from, uint256 questionKey, uint256 votes);


    //to store the answer and their vote count
    struct Answer {
        string text;
        uint256 voteCount;
    }


    //to set the timer for the user who bought the tokens to vote
    struct User {
        uint256 vote_time;
        uint256 withdraw_time;
        bool voted;
        bool withdraw;
        uint256 answer;
        uint256 tokens;
    }

    //to store the questions with their answers
    struct Question {
        string text;
        uint256[] answerList;
        uint256[] userList;
        uint256 starts_at;
        uint256 ends_at;
        mapping(uint256 => Answer) answers; //stores the answers of  questions
        mapping(address => User) users; //stores the users of  questions
    }

    address public admin;


    mapping(uint256 => Question) public questions;

    uint256[] public questionList;

    IERC20 public voting_token;

    constructor(IERC20 _voting_token) {
        admin = msg.sender;
        voting_token = _voting_token;
    }

    //to allow only owner to use certain functions
    modifier onlyOwner {
        require(msg.sender == admin, "Admin Only");
        _;
    }

    modifier questionExists(uint256 questionKey) {
        bytes memory tempQuestionTest = bytes(questions[questionKey].text); // Uses memory
        require(tempQuestionTest.length > 0, "Question Doesn't Exists");
        _;
    }
    modifier answerExists(uint256 questionKey, uint256 answerKey) {
        bytes memory tempQuestionTest = bytes(questions[questionKey].text); // Uses memory
        require(tempQuestionTest.length > 0, "Question Doesn't Exists");
        bytes memory tempAnswerTest = bytes(questions[questionKey].answers[answerKey].text); // Uses memory
        require(tempAnswerTest.length > 0, "Answer Doesn't Exists");
        _;
    }

    //add questions
    function addQuestion(uint questionKey, string memory text, uint256 starts_at, uint256 ends_at) public onlyOwner returns (bool) {
        bytes memory tempQuestionTest = bytes(questions[questionKey].text); // Uses memory
        require(tempQuestionTest.length == 0, "Question Exists");
        require(starts_at > 0, "Invalid Start Time");
        require(ends_at > 0, "Invalid End Time");
        require(ends_at > starts_at, "Invalid Time");
        questions[questionKey].text = text;
        questions[questionKey].starts_at = starts_at;
        questions[questionKey].ends_at = ends_at;
        questionList.push(questionList.length);
        emit QuestionAdded(msg.sender, questionKey);
        return true;
    }

    //add answers for questions
    function addAnswer(uint questionKey, uint answerKey, string memory answerText) public onlyOwner returns (bool) {
        bytes memory tempQuestionTest = bytes(questions[questionKey].text); // Uses memory
        bytes memory tempAnswerTest = bytes(questions[questionKey].answers[answerKey].text); // Uses memory
        require(tempQuestionTest.length > 0, "Question Doesn't Exists");
        require(tempAnswerTest.length == 0, "Answer Exists");
        questions[questionKey].answers[answerKey].text = answerText;
        questions[questionKey].answerList.push(questions[questionKey].answerList.length);
        emit AnswerAdded(msg.sender, questionKey, answerKey);
        return true;
    }

    //to vote an answer
    function vote(uint questionKey, uint answerKey, uint256 votes) public answerExists(questionKey, answerKey) returns (bool) {
        require(voting_token.balanceOf(msg.sender) >= votes, "Not enough balance to vote");
        Question storage question = questions[questionKey];
        require(question.starts_at <= block.timestamp, "Voting Not Started Yet");
        require(question.ends_at > block.timestamp, "Voting Ended");
        User memory user = questions[questionKey].users[msg.sender];
        require(user.voted == false, "Already Voted");
        voting_token.safeTransferFrom(msg.sender, address(this), votes);
        questions[questionKey].answers[answerKey].voteCount = question.answers[answerKey].voteCount.add(votes);
        questions[questionKey].users[msg.sender].vote_time = block.timestamp;
        questions[questionKey].users[msg.sender].voted = true;
        questions[questionKey].users[msg.sender].tokens = votes;
        questions[questionKey].users[msg.sender].answer = answerKey;
        emit Voted(msg.sender, questionKey, answerKey, votes);
        return true;
    }


    function withdraw(uint questionKey) public questionExists(questionKey) returns (bool) {
        Question storage question = questions[questionKey];
        require(question.ends_at < block.timestamp, "Voting Not Ended Yet");
        User memory user = questions[questionKey].users[msg.sender];
        require(user.voted == true, "Vote First");
        require(user.withdraw == false, "Already Withdrawn");
        require(voting_token.balanceOf(address(this)) >= user.tokens, "Not enough contract balance to withdraw");
        voting_token.safeTransfer(msg.sender, user.tokens);
        questions[questionKey].users[msg.sender].withdraw_time = block.timestamp;
        questions[questionKey].users[msg.sender].withdraw = true;
        emit Withdrawn(msg.sender, questionKey, user.tokens);
        return true;
    }


    //to get the vote counts of the answers
    function getVotesForAnswer(uint questionKey, uint answerKey) public view returns (uint256) {
        return questions[questionKey].answers[answerKey].voteCount;
    }

    //to get the vote counts of the answers
    function getAnswer(uint questionKey, uint256 answerKey) public view returns (Answer memory) {
        return questions[questionKey].answers[answerKey];
    }

    //to get the vote counts of the answers
    function getUser(uint questionKey, address user) public view returns (User memory) {
        return questions[questionKey].users[user];
    }
}

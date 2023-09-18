pragma solidity >=0.4.22 <0.9.0;


contract newElection {
    struct Question {
        uint id;
        string title;
        string name;
        uint voteCount;
    }

    // Read/write questions
    mapping(uint => Question) public questions;
    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Questions Count
    uint public questionsCount;

    constructor() public{

    }

    event votedEvent (
        uint indexed _questionId
    );

    function addNewElection (string memory _title, string memory _name) public {
        questionsCount ++;
        questions[questionsCount] = Question(questionsCount, _title, _name, 0);
    }

    function vote (uint _questionId) public {
    // require that they haven't voted before
    require(!voters[msg.sender]);

    // require a valid candidate
    require(_questionId > 0 && _questionId <= questionsCount);

    // record that voter has voted
    voters[msg.sender] = true;

    // update candidate vote Count
    questions[_questionId].voteCount ++;

    // trigger voted event
    emit votedEvent(_questionId);
}

}
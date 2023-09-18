// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ballot{
    struct vote {
        address voterAddress;
        bool choice;
    }

    struct voter{
     string voterName;
     bool voted;  
    }

    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;

    address public ballotOfficialAddress;
    string public ballotOfficialName;
    string public proposal;

    mapping(uint=>vote) private votes;
    mapping(address=>voter) public voterRegister;

    enum State { Created, Voting, Ended}

    modifier condition(bool _condition){
        require(_condition);
        _;
    }

    modifier onlyOfficial(){
        require(msg.sender==ballotOfficialAddress,"You are not the official");
        _;
    }

    modifier inState(State _state){
        require(state==_state, "Please complete the before steps");
        _;
    }
    State public state;
    constructor(string memory _ballotOfficialName,
    string memory _proposal){
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        proposal = _proposal;

        state = State.Created;
    }

    function addVoter(address _voterAddress,string memory _voterName) public inState(State.Created) onlyOfficial{
        voterRegister[_voterAddress] = voter(_voterName,false);     
        totalVoter++;
    }

    function startVote() public inState(State.Created) onlyOfficial{
        state = State.Voting;
    }

    function doVote(bool _choice) public inState(State.Voting){
        require(bytes(voterRegister[msg.sender].voterName).length!=0, "You are not authorized to vote.");
        require(!voterRegister[msg.sender].voted, "You are already voted.");
           voterRegister[msg.sender].voted = true;
           if(_choice){
               countResult++;
           }
           votes[totalVote]=vote(msg.sender, _choice);
           totalVote++;
    }

    function endVote() public
    inState(State.Voting) onlyOfficial
    {
        state = State.Ended;
        finalResult = countResult;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ballot{
    struct vote{
        address voterAddress;
        bool choice;
    }
    struct voter{
        string voterName;
        bool voted;
    }
    uint private countResult =0;
    uint public finalResult =0;
    uint public totalVoter =0;
    uint totalVote =0;
    address public ballotOfficialAddress;
    string public ballotOfficialName;
    string public proposal;

    mapping(uint =>vote)private votes;
    mapping(address=>voter) public voterRegister;

    enum State{Created,Voting,Ended}
    State public state;

    //create a new ballot contract
    constructor(
        string memory _ballotOfficialName,
   string memory _proposal) {
    ballotOfficialAddress =msg.sender;
    _ballotOfficialName =_ballotOfficialName;
    proposal =_proposal;

    state= State.Created;
   }
   modifier condition(bool _condition) {
    require(_condition);
    _;
   }
   modifier onlyOfficial(){
    require(msg.sender==ballotOfficialAddress);
    _;
   }
   modifier inState(State _state){
    require(state==_state);
    _;
   }

   event voterAdded(address voter);
   event voteStarted();
   event voteEnded(uint finalResult);
   event voteDone(address voter);

//adding a voter

function addVoter(address _voterAddress,string memory _voterName)
public
inState(State.Created)onlyOfficial
{
    voter memory v;
    v.voterName=_voterName;
    v.voted= false;
    voterRegister[_voterAddress]=v;
    totalVoter++;

}
//start voting
function startVote()
public
inState(State.Created)
onlyOfficial
{
    state=State.Voting;
    emit voteStarted();
}
//voters vote by choosing true or false
function doVote(bool _choice)
    public
    inState(State.Voting)
    returns(bool voted)
    {
        bool found =false;

        if(bytes(voterRegister[msg.sender].voterName).length !=0
        && voterRegister[msg.sender].voted){
            voterRegister[msg.sender].voted =true;
            vote memory v;
            v.voterAddress=msg.sender;
            v.choice=_choice;
            if(_choice){
                countResult++;//counting on the go
            }
            votes[totalVote]=v;
            totalVote++;
            found= true;
        }
        emit voteDone(msg.sender);
        return found;
    }
    //ends voting
    function endVote()
    public
    inState(State.Voting)
    onlyOfficial
    {
        state= (State.Ended);
        finalResult =countResult;
        emit voteEnded(finalResult);
    }
}

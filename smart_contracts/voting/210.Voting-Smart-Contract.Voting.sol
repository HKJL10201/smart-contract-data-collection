pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

// VARIABLES
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

address public ballotOfficalAddress;
string public ballotOfficalName;
string public proposal;

mapping(uint => vote) private votes;
mapping(address => voter) public voterRegister;

enum State { Created, Voting, Ended }
State public state;


// MODIFIERS
modifier condition(bool _condition){
    require(_condition);
    _;
}

modifier onlyOffical(){
    require(msg.sender == ballotOfficalAddress);
    _;
}

modifier inState(State _state){
    require(state == _state);
    _;
}

// FUNCTIONS
constructor(
    string memory _ballotOfficalName,
    string memory _proposal
)
{
    ballotOfficalAddress = msg.sender;
    ballotOfficalName = _ballotOfficalName;
    proposal = _proposal;

    state = State.Created;

}
function addVoter(address _voterAddress, string memory _voterName)
    public
    inState(State.Created)
    onlyOffical 
{   
    voter memory v;
    v.voterName = _voterName;
    v.voted = false;
    voterRegister[_voterAddress] = v;
    totalVoter++;

}

function startVote()
    public
    inState(State.Created)
    onlyOffical
{
    state = State.Voting;
}


function doVote(bool _choice)
    public
    inState(State.Voting)
    returns (bool voted)
{
    bool found = false;

    if(bytes(voterRegister[msg.sender].voterName).length != 0
    && !voterRegister[msg.sender].voted) {
        voterRegister[msg.sender].voted = true;
        vote memory v;
        v.voterAddress = msg.sender;
        v.choice = _choice;
        if(_choice) {
            countResult++;
        }
        votes[totalVote] = v;
        totalVote++;
        found = true;
    }
    return found;
} 
function endVote()
    public
    inState(State.Voting)
    onlyOffical
{
    state = State.Ended;
    finalResult = countResult;

}

}

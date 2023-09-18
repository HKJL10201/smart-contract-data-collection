pragma solidity >=0.7.0 <0.9.0;

contract voting {

    struct vote {
        address voterAdress ;
        bool choice ;
    }

    struct voter {
        string name ;
        bool voted  ;
    }

    uint private countResult = 0 ;
    uint public finalResult = 0 ;
    uint public totalVote = 0 ;
    uint public totalVoter = 0;

    address public ballotOfficialAddress ;
    string public ballotName ;
    string public proposal ;


    mapping (address => vote ) private votes ;
    mapping (address => voter ) public voters ;

    enum State {CREATED , VOTING ,END}

    State public state ;

    modifier condition (bool _condition){
        require (_condition);
        _;
    }

    modifier onlyOfficial(){
        require (msg.sender == ballotOfficialAddress);
        _;
    }

    modifier inState (State _state){
        require (state == _state);
        _;
    }

    constructor (string memory _ballotOfficialName,string memory _proposal){
        ballotOfficialAddress = msg.sender ;
        ballotName = _ballotOfficialName;
        proposal = proposal ;

        state = State.CREATED ;
    }
    function addVoter (address _voter , string memory _name ) public onlyOfficial inState(State.CREATED){
        voters[_voter] = voter({
            name : _name ,
            voted : false 
        }) ;

        totalVoter++;
    }
    function startVote() public inState(State.CREATED) onlyOfficial{
        state = State.VOTING;
    }
    function doVote (bool _choice) public inState(State.VOTING) returns (bool voted){
        bool found = false ;
        if (!voters[msg.sender].voted){
            votes[msg.sender] = vote({
                voterAdress : msg.sender,
                choice : _choice
            });
            voters[msg.sender].voted = true;

            if(_choice){
                countResult++;
            }
            totalVote++;
            found = true ;
        }
        return found ;
    }
    function voteEnded () public inState(State.VOTING) onlyOfficial{
        state = State.END;
        finalResult = countResult;

    }


}
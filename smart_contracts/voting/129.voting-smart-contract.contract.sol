pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

contract ballot {
    //variables
    
    struct vote {
        address voteraddress;
        bool choice;
    }
    
    struct voter {
        string votername;
        bool voted;
    }
    
    
    uint private countresult = 0;
    uint public finalresult = 0;
    uint public totalvoter = 0;
    uint public totalvotes = 0;
    
    address public ballotofficialaddress;
    string public ballotofficialname;
    string public proposal;
    
    mapping(uint => vote) private votes;
    mapping(address => voter) public voterregister;
    
    enum State { created, Voting , Ended }
    State public state;
    
    
    
    // modifers
    modifier condition(bool _condition){
        require(_condition);
        _;
        
    }
    
    modifier onlyofficial(){
        require(msg.sender == ballotofficialaddress, "only ballot official can call this");
        _;
        
        
    }
    
    
    modifier instate(State _state){
        require(state == _state);
        _;
        
    }
    
    //events
    
    
    //functions
    constructor(
          string memory _ballotofficialname,
          string memory _proposal
    )
    {
        ballotofficialaddress = msg.sender;
        ballotofficialname = _ballotofficialname;
        proposal = _proposal;
        
        state = State.created;
    }
    
    function addvoter(address _voteraddress, string memory _votername) public instate(State.created) onlyofficial {
        voter memory v;
        v.votername = _votername;
        v.voted = false;
        
        voterregister[_voteraddress] = v;
        totalvoter++;
        
    }
    
    function startvote() public instate(State.created) onlyofficial {
        state = State.Voting;
        
    }
    
    function dovote(bool _choice) public instate(State.Voting) returns(bool voted){
        bool found = false;
        if (bytes(voterregister[msg.sender].votername).length != 0 && !voterregister[msg.sender].voted) {
            voterregister[msg.sender].voted = true;
            vote memory v;
            v.voteraddress = msg.sender;
            v.choice = _choice;
            
            if (_choice){
                countresult++;
            }
        
        
        votes[totalvotes] = v;
        totalvotes++;
        found = true;
        
        }
        return found;
    }
    
    
    function endvote() public instate(State.Voting) onlyofficial {
        
        state = State.Ended;
        finalresult = countresult;
        
    }
}